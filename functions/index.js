const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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


exports.onAdminUserCreate = functions.auth.user()
  .onCreate(async (user) => {
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