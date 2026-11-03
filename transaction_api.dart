import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TransactionApi {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'SAVYYK_API_URL',
  );

  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:3001';
    }
    return 'http://10.0.2.2:3001';
  }

  Future<void> recordAuthActivity({
    required String identity,
    required String displayName,
    required String event,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/auth/activity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'identity': identity,
            'displayName': displayName,
            'event': event,
          }),
        )
        .timeout(const Duration(seconds: 5));
    _decodeResponse(response, expectedStatus: response.statusCode == 201 ? 201 : 200);
  }

  Future<Map<String, dynamic>> fetchAnalytics() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/analytics'))
        .timeout(const Duration(seconds: 10));
    return _decodeResponse(response, expectedStatus: 200);
  }

  Future<Map<String, dynamic>> createRazorpayOrder({
    required int amount,
    required String userId,
    required String userName,
    required String goalTitle,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/create-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount,
            'userId': userId,
            'userName': userName,
            'goalTitle': goalTitle,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response, expectedStatus: 201);
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
            'paymentId': paymentId,
            'signature': signature,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response, expectedStatus: 200);
  }

  Future<void> recordTransaction({
    required String type,
    required int amount,
    required String userId,
    required String userName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/transactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'type': type,
            'amount': amount,
            'userId': userId,
            'userName': userName,
          }),
        )
        .timeout(const Duration(seconds: 8));
    _decodeResponse(response, expectedStatus: 201);
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    required int expectedStatus,
  }) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode == expectedStatus && decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map && decoded['error'] is String) {
        throw Exception(decoded['error'] as String);
      }
    } on FormatException {
      // Fall through to the generic response error below.
    }
    throw Exception('The server could not process the payment request.');
  }
}
