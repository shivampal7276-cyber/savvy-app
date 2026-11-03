import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'transaction_api.dart';

/// Device-local demo session. Passwords are deliberately never persisted.
class AuthSession {
  static const _signedInKey = 'savyyk.session.signed_in';
  static const _emailKey = 'savyyk.session.email';
  static const _nameKey = 'savyyk.session.name';

  static String _accountNameKey(String email) {
    final encodedEmail = base64Url.encode(utf8.encode(email.trim().toLowerCase()));
    return 'savyyk.account.$encodedEmail.name';
  }

  static Future<bool> get isSignedIn async =>
      (await SharedPreferences.getInstance()).getBool(_signedInKey) ?? false;

  static Future<String?> get email async =>
      (await SharedPreferences.getInstance()).getString(_emailKey);

  static Future<String?> get name async =>
      (await SharedPreferences.getInstance()).getString(_nameKey);

  /// Stores a demo profile name so a later sign-in on this device can restore it.
  /// Passwords are intentionally not saved; this is not server authentication.
  static Future<void> registerDemoProfile({
    required String email,
    required String name,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accountNameKey(email), name.trim());
  }

  static Future<String?> demoProfileName(String email) async =>
      (await SharedPreferences.getInstance()).getString(_accountNameKey(email));

  static Future<void> save({required String email, required String name, String event = 'sign_in'}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_emailKey, email.trim());
    await preferences.setString(_nameKey, name.trim());
    await preferences.setBool(_signedInKey, true);
    try {
      await TransactionApi().recordAuthActivity(
        identity: email.trim(),
        displayName: name.trim(),
        event: event,
      );
    } catch (_) {
      // Keep local demo sign-in available if the backend is offline.
    }
  }

  static Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_signedInKey);
    await preferences.remove(_emailKey);
    await preferences.remove(_nameKey);
  }
}
