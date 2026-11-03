import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/linked_bank_store.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  static const _banks = [
    'Axis Bank', 'HDFC Bank', 'ICICI Bank', 'State Bank of India',
    'Punjab National Bank', 'Bank of Baroda', 'Canara Bank',
    'Bank of Maharashtra', 'Central Bank of India', 'City Union Bank',
    'IDBI Bank', 'Indian Bank', 'Indian Overseas Bank',
    'Jammu & Kashmir Bank', 'Karnataka Bank', 'Kotak Mahindra Bank',
    'Union Bank of India', 'Yes Bank',
  ];

  final _formKey = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _account = TextEditingController();
  final _confirmAccount = TextEditingController();
  final _ifsc = TextEditingController();
  String _query = '';
  String? _selectedBank;
  LinkedBank? _linkedBank;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    LinkedBankStore.load().then((bank) {
      if (mounted) setState(() => _linkedBank = bank);
    });
  }

  @override
  void dispose() {
    _holder.dispose();
    _account.dispose();
    _confirmAccount.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _saveBank() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose your bank to continue.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final bank = LinkedBank(
      name: _selectedBank!,
      accountHolder: _holder.text.trim(),
      lastFour: _account.text.trim().substring(_account.text.trim().length - 4),
    );
    await LinkedBankStore.save(bank);
    if (!mounted) return;
    setState(() {
      _linkedBank = bank;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bank details saved on this device.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final filteredBanks = _banks
        .where((bank) => bank.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xff040A1C),
        title: const Text('Bank account', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff111B3C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: .25)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.shield_outlined, color: Colors.cyanAccent),
                SizedBox(width: 12),
                Expanded(child: Text(
                  'This form only saves bank details on this device. It does not verify or connect your bank, and it cannot receive or withdraw money. Razorpay Checkout is separate and opens when you pay from Add Money.',
                  style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
                )),
              ]),
            ),
            const SizedBox(height: 22),
            if (_linkedBank != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xff111B3C), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.greenAccent),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_linkedBank!.maskedAccount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(_linkedBank!.accountHolder, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ])),
                  const Text('Saved', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('Replace linked bank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ] else ...[
              const Text('Choose your bank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 14),
            ],
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search banks', prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true, fillColor: const Color(0xff111B3C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            ...filteredBanks.map((bank) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: CircleAvatar(backgroundColor: const Color(0xff1A2547), child: Icon(
                _selectedBank == bank ? Icons.check : Icons.account_balance,
                color: _selectedBank == bank ? Colors.cyanAccent : Colors.white70,
                size: 20,
              )),
              title: Text(bank, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              trailing: _selectedBank == bank ? const Icon(Icons.check_circle, color: Colors.cyanAccent) : null,
              onTap: () => setState(() => _selectedBank = bank),
            )),
            const SizedBox(height: 18),
            const Text('Account details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(children: [
                _field(_holder, 'Account holder name', textCapitalization: TextCapitalization.words,
                  validator: (value) => (value?.trim().isEmpty ?? true) ? 'Enter the account holder name' : null),
                const SizedBox(height: 12),
                _field(_account, 'Account number', keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.length < 9 || value.length > 18) ? 'Enter a valid account number' : null),
                const SizedBox(height: 12),
                _field(_confirmAccount, 'Confirm account number', keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value != _account.text ? 'Account numbers do not match' : null),
                const SizedBox(height: 12),
                _field(_ifsc, 'IFSC code', textCapitalization: TextCapitalization.characters,
                  validator: (value) => !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch((value ?? '').trim().toUpperCase()) ? 'Enter a valid 11-character IFSC code' : null),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 54, child: ElevatedButton(
              onPressed: _saving ? null : _saveBank,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(_saving ? 'Saving…' : 'Save bank details', style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller, keyboardType: keyboardType,
    textCapitalization: textCapitalization, inputFormatters: inputFormatters,
    validator: validator, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60),
      filled: true, fillColor: const Color(0xff111B3C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
  );
}
