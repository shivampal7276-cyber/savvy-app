import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Widgets/gradient_button.dart';
import 'bank_account_screen.dart';
import 'account_auth_screen.dart';
import '../transaction_store.dart';
import 'goal_data_store.dart';
import '../services/transaction_api.dart';
import '../services/linked_bank_store.dart';
import '../services/auth_session.dart';

class WithdrawMoneyScreen extends StatefulWidget {
  final String goalTitle;
  final String goalEmoji;
  final int currentGoalBalance; // Yeh batane ke liye ki goal mein abhi kitne paise hain
  final String userId;
  final String userName;
  final bool isLoggedIn;

  const WithdrawMoneyScreen({
    super.key,
    this.goalTitle = "New laptop",
    this.goalEmoji = "💻",
    this.currentGoalBalance = 50,
    this.userId = "demo-user",
    this.userName = "Savyyk user",
    this.isLoggedIn = false,
  });

  @override
  State<WithdrawMoneyScreen> createState() => _WithdrawMoneyScreenState();
}

class _WithdrawMoneyScreenState extends State<WithdrawMoneyScreen> {
  int selectedAmount = 50;
  final List<int> amounts = [50, 100, 500, 1000];

  final GoalDataStore _goalStore = GoalDataStore();

  late String _selectedGoalTitle;
  late String _selectedGoalEmoji;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGoalTitle = widget.goalTitle;
    _selectedGoalEmoji = widget.goalEmoji;
  }

  Future<void> _processWithdrawal() async {
    if (_isSubmitting) return;
    if (!widget.isLoggedIn && !await AuthSession.isSignedIn) {
      final wantsLogin = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xff111B3C),
          title: const Text('Login required', style: TextStyle(color: Colors.white)),
          content: const Text('Sign in to request a withdrawal.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Continue')),
          ],
        ),
      );
      if (!mounted || wantsLogin != true) return;
      final signedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AccountAuthScreen(returnResultOnSuccess: true)),
      );
      if (!mounted || signedIn != true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have successfully logged in.')),
      );
    }
    // Check karein ki withdraw karne wala amount current balance se zyada na ho
    if (selectedAmount > widget.currentGoalBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot withdraw more than your current goal balance!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final linkedBank = await LinkedBankStore.load();
      if (linkedBank == null) {
        final linked = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const BankAccountScreen()),
        );
        if (!mounted || linked != true) return;
      }
      final email = await AuthSession.email;
      final name = await AuthSession.name;
      await TransactionApi().recordTransaction(
        type: 'withdrawal',
        amount: selectedAmount,
        userId: email ?? widget.userId,
        userName: name ?? widget.userName,
      );
      if (!mounted) return;
      _goalStore.addAmountToGoal(_selectedGoalTitle, -selectedAmount);
      TransactionStore().addTransaction(
        goalTitle: _selectedGoalTitle,
        amount: selectedAmount.toString(),
        isDeposit: false,
      );
      Navigator.pop(context, {
        "withdrawnAmount": selectedAmount,
        "goalTitle": _selectedGoalTitle,
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not record withdrawal: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCustomAmountDialog() {
    TextEditingController customController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff111B3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text(
            "Enter withdraw amount",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: customController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: "₹ ",
              prefixStyle: TextStyle(color: Colors.redAccent, fontSize: 20),
              hintText: "0",
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () {
                int? parsed = int.tryParse(customController.text);
                if (parsed != null && parsed > 0) {
                  setState(() {
                    selectedAmount = parsed;
                  });
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                "Apply",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCustomSelected = !amounts.contains(selectedAmount);

    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Withdraw money",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              // Display box showing withdrawal amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Text("₹ ", style: TextStyle(fontSize: 32, color: Colors.white60, fontWeight: FontWeight.bold)),
                    Text(
                      "$selectedAmount",
                      style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 4, top: 8),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Available in goal: ₹${widget.currentGoalBalance}",
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...amounts.map((amt) {
                    bool isSelected = selectedAmount == amt;
                    return GestureDetector(
                      onTap: () => setState(() => selectedAmount = amt),
                      child: Container(
                        width: 95,
                        height: 55,
                        decoration: BoxDecoration(
                          color: isSelected ? null : const Color(0xff111B3C),
                          gradient: isSelected
                              ? const LinearGradient(colors: [Color(0xffFF416C), Color(0xffFF4B2B)])
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
                        ),
                        child: Center(
                          child: Text(
                            "₹$amt",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _showCustomAmountDialog,
                    child: Container(
                      width: 110,
                      height: 55,
                      decoration: BoxDecoration(
                        color: isCustomSelected ? null : const Color(0xff111B3C),
                        gradient: isCustomSelected
                            ? const LinearGradient(colors: [Color(0xffFF416C), Color(0xffFF4B2B)])
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isCustomSelected ? Colors.transparent : Colors.white12),
                      ),
                      child: Center(
                        child: Text(
                          isCustomSelected ? "₹$selectedAmount" : "Custom",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xff111B3C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: FutureBuilder<LinkedBank?>(
                    future: LinkedBankStore.load(),
                    builder: (context, snapshot) => Row(children: [
                      const Icon(Icons.account_balance, color: Colors.white70),
                      const SizedBox(width: 14),
                      const Text("Withdraw to", style: TextStyle(color: Colors.white, fontSize: 15)),
                      const Spacer(),
                      Text(snapshot.data?.maskedAccount ?? 'Add bank account',
                        style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Text("🎯", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 14),
                    const Text("From Goal", style: TextStyle(color: Colors.white, fontSize: 15)),
                    const Spacer(),
                    Text("$_selectedGoalEmoji $_selectedGoalTitle", style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Demo mode: this updates the in-app balance only; no bank transfer occurs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              const SizedBox(height: 10),
              // Withdraw confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF4B2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _processWithdrawal,
                  child: Text(
                    _isSubmitting ? "Connecting to server..." : "Confirm & withdraw ₹$selectedAmount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
