import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef RazorpaySuccessCallback = Future<void> Function(
  String orderId,
  String paymentId,
  String signature,
);
typedef RazorpayErrorCallback = void Function(String message);

class RazorpayCheckout {
  RazorpayCheckout({required this.onSuccess, required this.onError}) {
    _razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  final RazorpaySuccessCallback onSuccess;
  final RazorpayErrorCallback onError;
  final Razorpay _razorpay = Razorpay();

  void open(Map<String, dynamic> options) => _razorpay.open(options);

  void _handleSuccess(PaymentSuccessResponse response) {
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;
    if (orderId == null || paymentId == null || signature == null) {
      onError('Razorpay returned incomplete payment details.');
      return;
    }
    unawaited(onSuccess(orderId, paymentId, signature));
  }

  void _handleError(PaymentFailureResponse response) {
    onError(response.message ?? 'The Razorpay payment was not completed.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void dispose() => _razorpay.clear();
}
