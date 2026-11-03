import 'package:shared_preferences/shared_preferences.dart';

class LinkedBank {
  const LinkedBank({required this.name, required this.accountHolder, required this.lastFour});

  final String name;
  final String accountHolder;
  final String lastFour;

  String get maskedAccount => '$name  •• $lastFour';
}

/// Stores only a display name and the last four digits. Full account numbers
/// and IFSC values are never written to local storage.
class LinkedBankStore {
  static const _bankKey = 'savyyk.bank.name';
  static const _holderKey = 'savyyk.bank.holder';
  static const _lastFourKey = 'savyyk.bank.last_four';

  static Future<LinkedBank?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString(_bankKey);
    final holder = preferences.getString(_holderKey);
    final lastFour = preferences.getString(_lastFourKey);
    if (name == null || holder == null || lastFour == null) return null;
    return LinkedBank(name: name, accountHolder: holder, lastFour: lastFour);
  }

  static Future<void> save(LinkedBank bank) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_bankKey, bank.name);
    await preferences.setString(_holderKey, bank.accountHolder);
    await preferences.setString(_lastFourKey, bank.lastFour);
  }
}
