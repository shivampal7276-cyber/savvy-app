import 'dart:async';
import 'dart:js_util' as js;

typedef RazorpaySuccessCallback = Future<void> Function(
  String orderId,
  String paymentId,
  String signature,
);
typedef RazorpayErrorCallback = void Function(String message);

class RazorpayCheckout {
  RazorpayCheckout({required this.onSuccess, required this.onError});

  final RazorpaySuccessCallback onSuccess;
  final RazorpayErrorCallback onError;
  bool _completed = false;

  void open(Map<String, dynamic> options) {
    final constructor = js.getProperty(js.globalThis, 'Razorpay');
    if (constructor == null) {
      onError('Razorpay Checkout did not load. Refresh the page and try again.');
      return;
    }

    _completed = false;
    final checkoutOptions = Map<String, dynamic>.from(options)
      ..['handler'] = js.allowInterop((dynamic response) {
        _completed = true;
        final orderId = js.getProperty(response, 'razorpay_order_id') as String?;
        final paymentId = js.getProperty(response, 'razorpay_payment_id') as String?;
        final signature = js.getProperty(response, 'razorpay_signature') as String?;
        if (orderId == null || paymentId == null || signature == null) {
          onError('Razorpay returned incomplete payment details.');
          return;
        }
        unawaited(onSuccess(orderId, paymentId, signature));
      })
      ..['modal'] = {
        'ondismiss': js.allowInterop(() {
          if (!_completed) onError('Razorpay checkout was cancelled.');
        }),
      };

    try {
      final checkout = js.callConstructor<dynamic>(constructor, [js.jsify(checkoutOptions)]);
      js.callMethod<void>(
        checkout,
        'on',
        [
          'payment.failed',
          js.allowInterop((dynamic response) {
            _completed = true;
            final error = js.getProperty(response, 'error');
            final description = error == null ? null : js.getProperty(error, 'description');
            onError(description is String ? description : 'The Razorpay payment was not completed.');
          }),
        ],
      );
      js.callMethod<void>(checkout, 'open', const []);
    } catch (error) {
      onError('Could not open Razorpay Checkout: $error');
    }
  }

  void dispose() {}
}
