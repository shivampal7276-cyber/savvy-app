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

  void open(Map<String, dynamic> options) {
    onError('Razorpay checkout is not supported on this platform.');
  }

  void dispose() {}
}
