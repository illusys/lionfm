import 'package:flutter/material.dart';
import '../../core/constants/app_config.dart';

sealed class PaymentResult {
  factory PaymentResult.success({required String reference}) =
      PaymentSuccess;
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

class PaystackService {
  static final String _publicKey = AppConfig.paystackPublicKey;

  Future<void> initialize() async {
    // flutter_paystack plugin.initialize(_publicKey) called here
    // in production, after importing the plugin.
    debugPrint('Paystack initialized with key: $_publicKey');
  }

  Future<PaymentResult> chargePremium({
    required BuildContext context,
    required String email,
    required String userName,
  }) async {
    final reference = _generateReference();
    try {
      // In production:
      // final charge = Charge()
      //   ..amount = 100000
      //   ..reference = reference
      //   ..email = email
      //   ..currency = 'NGN';
      // final response = await plugin.checkout(context, charge: charge,
      //     method: CheckoutMethod.card, fullscreen: false);
      // if (response.status == true) return PaymentResult.success(reference: reference);
      // return PaymentResult.cancelled();

      // Demo: simulate success after 1s
      await Future.delayed(const Duration(seconds: 1));
      return PaymentResult.success(reference: reference);
    } catch (e) {
      return PaymentResult.error(message: e.toString());
    }
  }

  String _generateReference() =>
      'LIONFM_PREM${DateTime.now().millisecondsSinceEpoch}';
}
