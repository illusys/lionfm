const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');
const crypto = require('crypto');

admin.initializeApp();

// ── Helper: make an HTTPS request to Paystack API ────────────────────────────

function paystackRequest(method, path, body, secretKey) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'api.paystack.co',
      port: 443,
      path,
      method,
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let raw = '';
      res.on('data', (chunk) => (raw += chunk));
      res.on('end', () => {
        try {
          resolve(JSON.parse(raw));
        } catch (_) {
          reject(new Error('Invalid JSON from Paystack'));
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// ── FCM: send notification when queued ───────────────────────────────────────

exports.sendNotification = functions.firestore
  .document('notification_queue/{docId}')
  .onCreate(async (snap) => {
    const data = snap.data();

    const message = {
      notification: {
        title: data.title || 'Lion FM',
        body: data.body || '',
      },
      topic: data.topic || 'all_listeners',
    };

    await admin.messaging().send(message);

    await snap.ref.update({
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// ── Auth: wire admin role from invite on first sign-in ───────────────────────

exports.onAdminUserCreate = functions.auth.user().onCreate(async (user) => {
  if (!user.email) return null;

  const db = admin.firestore();
  const inviteRef = db.collection('admin_invites').doc(user.email);
  const inviteDoc = await inviteRef.get();

  if (!inviteDoc.exists) return null;

  await db.collection('users').doc(user.uid).set({
    email: user.email,
    role: inviteDoc.data().role || 'none',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return null;
});


// ── Bootstrap: first-time setup status ──────────────────────────────────────

exports.getAdminBootstrapStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  const snap = await admin.firestore()
    .collection('users')
    .where('role', '==', 'superAdmin')
    .limit(1)
    .get();
  return { needsFirstTimeSetup: snap.empty };
});

// ── Audit helper ────────────────────────────────────────────────────────────

async function writeAuditLog(action, actorUid, targetPath, details = {}) {
  await admin.firestore().collection('admin_audit_logs').add({
    action,
    actorUid: actorUid || null,
    targetPath: targetPath || null,
    details,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ── Paystack: initialize transaction ─────────────────────────────────────────
// Set secret via: firebase functions:config:set paystack.secret="sk_live_..."
// CAUTION: sk_live_* moves REAL MONEY. Test with sk_test_* first.

exports.initPaystackTransaction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  const config = functions.config();
  const secretKey = config.paystack && config.paystack.secret;
  if (!secretKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Paystack secret not configured. Run: firebase functions:config:set paystack.secret="sk_..."',
    );
  }

  const { email, productType, eventId } = data;
  if (!email || !productType) {
    throw new functions.https.HttpsError('invalid-argument', 'email and productType are required');
  }

  const db = admin.firestore();
  const uid = context.auth.uid;
  let amountKobo;
  let metadata;

  if (productType === 'premium') {
    amountKobo = 100000;
    metadata = { type: 'premium', userId: uid };
  } else if (productType === 'event_ticket') {
    if (!eventId) {
      throw new functions.https.HttpsError('invalid-argument', 'eventId is required for event tickets');
    }
    const eventSnap = await db.collection('events').doc(eventId).get();
    if (!eventSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Event not found');
    }
    const event = eventSnap.data();
    amountKobo = Math.max(0, Number(event.ticketPriceNGN || 0)) * 100;
    if (amountKobo <= 0) {
      throw new functions.https.HttpsError('failed-precondition', 'This event does not require payment');
    }
    metadata = { type: 'event_ticket', userId: uid, eventId };
  } else {
    throw new functions.https.HttpsError('invalid-argument', 'Unsupported productType');
  }

  const result = await paystackRequest(
    'POST',
    '/transaction/initialize',
    { email, amount: amountKobo, metadata },
    secretKey,
  );

  if (!result.status) {
    throw new functions.https.HttpsError('internal', result.message || 'Transaction init failed');
  }

  await writeAuditLog('payment_initialized', uid, `payment_attempts/${result.data.reference}`, { productType, eventId: eventId || null, amountKobo });

  await db.collection('payment_attempts').doc(result.data.reference).set({
    uid,
    email,
    productType,
    eventId: eventId || null,
    amountKobo,
    status: 'initialized',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    authorizationUrl: result.data.authorization_url,
    authorization_url: result.data.authorization_url,
    accessCode: result.data.access_code,
    reference: result.data.reference,
  };
});

// ── Paystack: verify payment and record ticket / premium ─────────────────────

exports.verifyPaystackPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  const config = functions.config();
  const secretKey = config.paystack && config.paystack.secret;
  if (!secretKey) {
    throw new functions.https.HttpsError('failed-precondition', 'Paystack not configured');
  }

  const { reference } = data;
  if (!reference) {
    throw new functions.https.HttpsError('invalid-argument', 'reference is required');
  }

  const result = await paystackRequest(
    'GET',
    `/transaction/verify/${encodeURIComponent(reference)}`,
    null,
    secretKey,
  );

  if (!result.status || result.data.status !== 'success') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Payment not successful: ${result.data ? result.data.status : (result.message || 'unknown')}`,
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;
  const metadata = result.data.metadata || {};
  const attemptRef = db.collection('payment_attempts').doc(reference);
  const attemptSnap = await attemptRef.get();
  const attempt = attemptSnap.exists ? attemptSnap.data() : null;
  if (attempt && attempt.uid !== uid) {
    throw new functions.https.HttpsError('permission-denied', 'Payment reference belongs to another user');
  }
  if (attempt && Number(attempt.amountKobo || 0) !== Number(result.data.amount || 0)) {
    throw new functions.https.HttpsError('failed-precondition', 'Payment amount mismatch');
  }

  // Record event ticket
  if (metadata.eventId) {
    const ticketId = `${uid}_${metadata.eventId}`;
    await writeAuditLog('ticket_paid', uid, `tickets/${ticketId}`, { eventId: metadata.eventId, amountKobo: result.data.amount });
    await db.collection('tickets').doc(ticketId).set(
      {
        userId: uid,
        eventId: metadata.eventId,
        reference,
        paid: true,
        amountKobo: result.data.amount,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  // Activate premium subscription
  if (metadata.type === 'premium') {
    await writeAuditLog('premium_activated', uid, `users/${uid}`, { reference });
    await db.collection('users').doc(uid).set({
      isPremium: true,
      premiumSince: admin.firestore.FieldValue.serverTimestamp(),
      premiumReference: reference,
    }, { merge: true });
  }

  if (attemptRef) {
    await attemptRef.set({ status: 'verified', verifiedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  }

  return {
    success: true,
    status: 'success',
    amount: result.data.amount,
    reference: result.data.reference,
  };
});

// ── Onboarding: provision a new station ──────────────────────────────────────
// Platform owner only. Creates the station doc, admin invite, and marks the
// onboarding request as provisioned.

exports.onboardStation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  const userSnap = await db.collection('users').doc(uid).get();
  const role = userSnap.exists ? userSnap.data().role : 'none';
  if (role !== 'platformOwner') {
    throw new functions.https.HttpsError('permission-denied', 'Platform owner only');
  }

  const { onboardingId, slug, plan, trialDays } = data;
  if (!onboardingId || !slug) {
    throw new functions.https.HttpsError('invalid-argument', 'onboardingId and slug are required');
  }

  // Validate slug: lowercase alphanumeric + hyphens
  if (!/^[a-z0-9-]{2,30}$/.test(slug)) {
    throw new functions.https.HttpsError('invalid-argument', 'Slug must be 2–30 lowercase letters, numbers, or hyphens');
  }

  // Ensure slug is not already taken
  const existingStation = await db.collection('stations').doc(slug).get();
  if (existingStation.exists) {
    throw new functions.https.HttpsError('already-exists', `Slug "${slug}" is already taken`);
  }

  // Get the onboarding request
  const onboardingSnap = await db.collection('station_onboarding').doc(onboardingId).get();
  if (!onboardingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Onboarding request not found');
  }
  const ob = onboardingSnap.data();
  if (ob.status === 'provisioned') {
    throw new functions.https.HttpsError('already-exists', 'This request has already been provisioned');
  }

  // Calculate trial end date
  const trialEnd = new Date();
  trialEnd.setDate(trialEnd.getDate() + (Number(trialDays) || 30));

  const finalPlan = plan || ob.planPreference || 'starter';

  // Create station document
  await db.collection('stations').doc(slug).set({
    stationId: slug,
    name: ob.stationName || slug,
    slug,
    frequency: ob.frequency || '',
    tagline: 'Your Interactive Radio',
    logoUrl: '',
    faviconUrl: '',
    brandColors: {
      primary: '#1E9B43',
      secondary: '#28D7D2',
      accent: '#C89A29',
      background: '#0A0A0A',
    },
    streamUrl: '',
    streamType: 'byo',
    plan: finalPlan,
    planStatus: 'trialing',
    trialEndsAt: admin.firestore.Timestamp.fromDate(trialEnd),
    ownerUid: '',
    contactEmail: ob.contactEmail || '',
    customDomain: null,
    isActive: true,
    isFeatured: false,
    listenerCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create admin invite so the station owner can sign in and get superAdmin role
  if (ob.contactEmail) {
    await db.collection('admin_invites').doc(ob.contactEmail).set({
      email: ob.contactEmail,
      role: 'superAdmin',
      stationId: slug,
      invitedBy: uid,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  // Mark onboarding as provisioned
  await db.collection('station_onboarding').doc(onboardingId).update({
    status: 'provisioned',
    provisionedSlug: slug,
    reviewedBy: uid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAuditLog('station_provisioned', uid, `stations/${slug}`, {
    onboardingId, plan: finalPlan, trialDays: trialDays || 30,
  });

  return { success: true, stationId: slug };
});

// ── Paystack: initialize station subscription billing ────────────────────────
// Platform owner only. Generates a Paystack payment link for a station's
// monthly subscription fee. Secret must be set via functions:config.

const STATION_PLAN_PRICES_KOBO = {
  starter:     500000,  // ₦5,000 / month
  pro:        2000000,  // ₦20,000 / month
  enterprise: 5000000,  // ₦50,000 / month
};

exports.initStationBilling = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  // Only platform owners may generate billing links
  const userSnap = await db.collection('users').doc(uid).get();
  const role = userSnap.exists ? userSnap.data().role : 'none';
  if (role !== 'platformOwner') {
    throw new functions.https.HttpsError('permission-denied', 'Platform owner only');
  }

  const config = functions.config();
  const secretKey = config.paystack && config.paystack.secret;
  if (!secretKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Paystack secret not configured. Run: firebase functions:config:set paystack.secret="sk_..."',
    );
  }

  const { stationId, plan, billingEmail } = data;
  if (!stationId || !plan) {
    throw new functions.https.HttpsError('invalid-argument', 'stationId and plan are required');
  }

  const amountKobo = STATION_PLAN_PRICES_KOBO[plan];
  if (!amountKobo) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `No billing required for plan: ${plan}. Use 'starter', 'pro', or 'enterprise'.`,
    );
  }

  const stationSnap = await db.collection('stations').doc(stationId).get();
  if (!stationSnap.exists) {
    throw new functions.https.HttpsError('not-found', `Station "${stationId}" not found`);
  }
  const station = stationSnap.data();
  const email = billingEmail || station.contactEmail;
  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'No billing email available for this station');
  }

  const result = await paystackRequest(
    'POST',
    '/transaction/initialize',
    {
      email,
      amount: amountKobo,
      metadata: {
        type: 'station_subscription',
        stationId,
        plan,
        initiatedBy: uid,
      },
    },
    secretKey,
  );

  if (!result.status) {
    throw new functions.https.HttpsError('internal', result.message || 'Paystack transaction init failed');
  }

  const reference = result.data.reference;

  await writeAuditLog('station_billing_initialized', uid, `station_payments/${reference}`, {
    stationId, plan, amountKobo,
  });

  await db.collection('station_payments').doc(reference).set({
    stationId,
    plan,
    amountKobo,
    billingEmail: email,
    initiatedBy: uid,
    status: 'initialized',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    authorizationUrl: result.data.authorization_url,
    reference,
  };
});

// ── Paystack: webhook endpoint ────────────────────────────────────────────────
// Register this URL in your Paystack Dashboard → Settings → Webhooks.
// Verifies the x-paystack-signature header with HMAC-SHA512.
// Handles: event_ticket, premium, station_subscription

exports.paystackWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const config = functions.config();
  const secretKey = config.paystack && config.paystack.secret;
  if (!secretKey) {
    res.status(500).send('Paystack not configured');
    return;
  }

  const signature = req.headers['x-paystack-signature'];
  if (!signature) {
    res.status(400).send('Missing x-paystack-signature header');
    return;
  }

  const hash = crypto
    .createHmac('sha512', secretKey)
    .update(req.rawBody)
    .digest('hex');

  if (hash !== signature) {
    res.status(400).send('Invalid signature');
    return;
  }

  const event = req.body;

  if (event.event === 'charge.success') {
    const { data } = event;
    const metadata = (data && data.metadata) || {};
    const db = admin.firestore();

    // ── Event ticket ──────────────────────────────────────────────────────────
    if (metadata.userId && metadata.eventId) {
      const ticketId = `${metadata.userId}_${metadata.eventId}`;
      await writeAuditLog('ticket_paid', metadata.userId, `tickets/${ticketId}`, {
        eventId: metadata.eventId, amountKobo: data.amount,
      });
      await db.collection('tickets').doc(ticketId).set(
        {
          userId: metadata.userId,
          eventId: metadata.eventId,
          reference: data.reference,
          paid: true,
          amountKobo: data.amount,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    // ── Listener premium subscription ─────────────────────────────────────────
    if (metadata.userId && metadata.type === 'premium') {
      await writeAuditLog('premium_activated', metadata.userId, `users/${metadata.userId}`, {
        reference: data.reference,
      });
      await db.collection('users').doc(metadata.userId).set({
        isPremium: true,
        premiumSince: admin.firestore.FieldValue.serverTimestamp(),
        premiumReference: data.reference,
      }, { merge: true });
    }

    // ── Station subscription ──────────────────────────────────────────────────
    if (metadata.type === 'station_subscription' && metadata.stationId && metadata.plan) {
      const expectedKobo = STATION_PLAN_PRICES_KOBO[metadata.plan];
      if (expectedKobo && data.amount >= expectedKobo) {
        await db.collection('stations').doc(metadata.stationId).update({
          plan: metadata.plan,
          planStatus: 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await db.collection('station_payments').doc(data.reference).set({
          stationId: metadata.stationId,
          plan: metadata.plan,
          amountKobo: data.amount,
          billingEmail: data.customer && data.customer.email,
          reference: data.reference,
          status: 'paid',
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await writeAuditLog(
          'station_billing_paid',
          metadata.initiatedBy || null,
          `stations/${metadata.stationId}`,
          { plan: metadata.plan, amountKobo: data.amount, reference: data.reference },
        );
      }
    }
  }

  res.status(200).send('OK');
});
