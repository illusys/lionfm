import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

sealed class PaymentResult {
  factory PaymentResult.success({required String reference}) = PaymentSuccess;
  factory PaymentResult.cancelled() = PaymentCancelled;
  factory PaymentResult.error({required String message}) = PaymentError;
}

class PaymentSuccess implements PaymentResult {
  final String reference;
  PaymentSuccess({required this.reference});
}

class PaymentCancelled implements PaymentResult {
  PaymentCancelled();
}

class PaymentError implements PaymentResult {
  final String message;
  PaymentError({required this.message});
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Paystack integration.
///
/// PUBLIC KEY — stored in admin_config/payments.publicKey; safe to read in app.
/// SECRET KEY — lives ONLY in Cloud Function config, never in app or Firestore.
///   Set via: firebase functions:config:set paystack.secret="sk_live_…"
///
/// CAUTION: sk_live_* moves REAL MONEY. Always test with sk_test_* first.
/// Test cards: https://paystack.com/docs/payments/test-payments/
class PaystackService {
  static final _functions = FirebaseFunctions.instance;
  static final _db = FirebaseFirestore.instance;

  /// Reads the public key stored in admin_config by the superAdmin.
  static Future<String> _getPublicKey() async {
    try {
      final doc = await _db.collection('admin_config').doc('payments').get();
      return doc.data()?['publicKey'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Initialises a Paystack transaction for premium subscription (₦1,000/month)
  /// via Cloud Function, then opens the payment URL in the browser.
  /// Returns the Paystack reference the caller should pass to [verifyPayment].
  Future<PaymentResult> chargePremium({
    required String email,
    required String userId,
  }) async {
    return _initiateTransaction(
      email: email,
      userId: userId,
      amountKobo: 100000, // ₦1,000 × 100 kobo
      metadata: {'type': 'premium', 'userId': userId},
    );
  }

  /// Initiates a ticket purchase for the given event.
  Future<PaymentResult> chargeEventTicket({
    required String email,
    required String userId,
    required String eventId,
    required int ticketPriceNGN,
  }) async {
    return _initiateTransaction(
      email: email,
      userId: userId,
      amountKobo: ticketPriceNGN * 100,
      metadata: {'type': 'event_ticket', 'userId': userId, 'eventId': eventId},
    );
  }

  Future<PaymentResult> _initiateTransaction({
    required String email,
    required String userId,
    required int amountKobo,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final publicKey = await _getPublicKey();
      if (publicKey.isEmpty) {
        return PaymentResult.error(
            message: 'Paystack public key not configured. '
                'Contact your administrator.');
      }

      final callable = _functions.httpsCallable('initPaystackTransaction');
      final result = await callable.call<Map<Object?, Object?>>({
        'email': email,
        'amountKobo': amountKobo,
        'metadata': metadata,
        'publicKey': publicKey,
      });

      final data = Map<String, dynamic>.from(result.data);
      final authorizationUrl = data['authorization_url'] as String?;
      final reference = data['reference'] as String?;

      if (authorizationUrl == null || reference == null) {
        return PaymentResult.error(message: 'Invalid response from payment server.');
      }

      final launched = await launchUrl(
        Uri.parse(authorizationUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        return PaymentResult.error(
            message: 'Could not open payment page. Please try again.');
      }

      return PaymentSuccess(reference: reference);
    } on FirebaseFunctionsException catch (e) {
      return PaymentResult.error(message: e.message ?? e.code);
    } catch (e) {
      return PaymentResult.error(message: e.toString());
    }
  }

  /// Called after the user returns from the browser — verifies the reference
  /// via Cloud Function which updates Firestore on success.
  static Future<PaymentResult> verifyPayment({
    required String reference,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPaystackPayment');
      final result = await callable.call<Map<Object?, Object?>>({'reference': reference});
      final data = Map<String, dynamic>.from(result.data);
      if (data['success'] == true) {
        return PaymentSuccess(reference: reference);
      }
      return PaymentResult.error(message: data['message'] as String? ?? 'Verification failed.');
    } on FirebaseFunctionsException catch (e) {
      return PaymentResult.error(message: e.message ?? e.code);
    } catch (e) {
      return PaymentResult.error(message: e.toString());
    }
  }

}
