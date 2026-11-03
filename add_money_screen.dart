import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Widgets/gradient_button.dart';
import 'bank_safety_screen.dart';
import 'account_auth_screen.dart';
import '../transaction_store.dart';
import 'goal_data_store.dart';
import 'share_progress_screen.dart';
import '../services/transaction_api.dart';
import '../services/auth_session.dart';
import '../services/razorpay_checkout.dart';

class AddMoneyScreen extends StatefulWidget {
  final String goalTitle;
  final String goalEmoji;
  final bool isLoggedIn;
  final String userId;
  final String userName;
  final bool launchCheckoutImmediately;

  const AddMoneyScreen({
    super.key,
    this.goalTitle = "New phone",
    this.goalEmoji = "📱",
    this.isLoggedIn = false,
    this.userId = "demo-user",
    this.userName = "Savyyk user",
    this.launchCheckoutImmediately = false,
  });

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  int selectedAmount = 50;
  final List<int> amounts = [5, 50, 100, 200];

  final GoalDataStore _goalStore = GoalDataStore();

  late String _selectedGoalTitle;
  late String _selectedGoalEmoji;
  late bool _currentLoggedInStatus;
  bool _isSubmitting = false;
  late final RazorpayCheckout _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = RazorpayCheckout(
      onSuccess: _handlePaymentSuccess,
      onError: _finishPaymentWithError,
    );
    _selectedGoalTitle = widget.goalTitle;
    _selectedGoalEmoji = widget.goalEmoji;
    _currentLoggedInStatus = widget.isLoggedIn;

    bool exists = _goalStore.goals.any((g) => g["title"] == _selectedGoalTitle);
    if (!exists) {
      _goalStore.addNewGoal(_selectedGoalEmoji, _selectedGoalTitle, 50000);
    }
    if (widget.launchCheckoutImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _processAddingMoney();
      });
    }
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff111B3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Row(
            children: const [
              Text("🔒 ", style: TextStyle(fontSize: 20)),
              Text(
                "Login Required",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "You need to be logged in to add money to your goals and track your savings securely.",
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountAuthScreen(returnResultOnSuccess: true),
                  ),
                ).then((loggedIn) {
                  if (loggedIn == true) {
                    setState(() {
                      _currentLoggedInStatus = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You have successfully logged in.')),
                    );
                    _processAddingMoney();
                  }
                });
              },
              child: const Text(
                "Login Now",
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processAddingMoney() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final email = await AuthSession.email;
      final name = await AuthSession.name;
      final order = await TransactionApi().createRazorpayOrder(
        amount: selectedAmount,
        userId: email ?? widget.userId,
        userName: name ?? widget.userName,
        goalTitle: _selectedGoalTitle,
      );
      if (!mounted) return;
      _razorpay.open({
        'key': order['keyId'],
        'amount': order['amount'],
        'currency': order['currency'],
        'order_id': order['orderId'],
        'name': 'Savyyk',
        'description': 'Add money to $_selectedGoalTitle',
        'prefill': {
          if (email != null && email.isNotEmpty) 'email': email,
        },
        'theme': {'color': '#24D6FF'},
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start Razorpay checkout: $error')),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(
    String orderId,
    String paymentId,
    String signature,
  ) async {
    try {
      final result = await TransactionApi().verifyRazorpayPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      if (!mounted) return;
      final transaction = result['transaction'] as Map<String, dynamic>;
      final paidAmount = (transaction['amount'] as num).round();
      final paidGoalTitle = transaction['goalTitle'] as String;
      _goalStore.addAmountToGoal(paidGoalTitle, paidAmount);
      TransactionStore().addTransaction(
        goalTitle: paidGoalTitle,
        amount: paidAmount.toString(),
        isDeposit: true,
      );
      Navigator.pop(context, {
        'savedAmount': paidAmount,
        'goalTitle': paidGoalTitle,
      });
    } catch (error) {
      _finishPaymentWithError('Payment confirmation failed: $error');
    }
  }

  void _finishPaymentWithError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSelectedGoal() {
    final goal = _goalStore.goals.firstWhere(
      (item) => item["title"] == _selectedGoalTitle,
      orElse: () => {"emoji": _selectedGoalEmoji, "title": _selectedGoalTitle, "current": 0, "target": 0},
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareProgressScreen(
          goalTitle: _selectedGoalTitle,
          goalEmoji: _selectedGoalEmoji,
          savedAmountText: (goal["current"] ?? 0).toString(),
          targetAmountText: (goal["target"] ?? 0).toString(),
        ),
      ),
    );
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
            "Enter custom amount",
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
              prefixStyle: TextStyle(color: Colors.cyanAccent, fontSize: 20),
              hintText: "0",
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
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
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    final signedIn = _currentLoggedInStatus || await AuthSession.isSignedIn;
    if (!mounted) return;
    if (!signedIn) {
      _showLoginRequiredDialog();
      return;
    }
    setState(() => _currentLoggedInStatus = true);
    await _processAddingMoney();
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
                    "Add money",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 25),
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
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
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
                              ? const LinearGradient(colors: [Color(0xff2F7BFF), Color(0xff24D6FF)])
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
                        ),
                        child: Center(
                          child: Text(
                            "₹$amt",
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
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
                            ? const LinearGradient(colors: [Color(0xff2F7BFF), Color(0xff24D6FF)])
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isCustomSelected ? Colors.transparent : Colors.white12),
                      ),
                      child: Center(
                        child: Text(
                          isCustomSelected ? "₹$selectedAmount" : "Custom",
                          style: TextStyle(
                            color: isCustomSelected ? Colors.black : Colors.white,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(children: [
                  Icon(Icons.verified_user_outlined, color: Colors.cyanAccent),
                  SizedBox(width: 14),
                  Expanded(child: Text('Secure test checkout', style: TextStyle(color: Colors.white, fontSize: 15))),
                  Text('Razorpay', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                ]),
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
                    const Text("Goal", style: TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGoalTitle,
                          isExpanded: true,
                          dropdownColor: const Color(0xff111B3C),
                          iconEnabledColor: Colors.cyanAccent,
                          style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
                          items: _goalStore.goals.map((goal) {
                            final title = goal["title"].toString();
                            return DropdownMenuItem<String>(
                              value: title,
                              child: Text("${goal["emoji"]} $title", overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (title) {
                            if (title == null) return;
                            final goal = _goalStore.goals.firstWhere((item) => item["title"] == title);
                            setState(() {
                              _selectedGoalTitle = title;
                              _selectedGoalEmoji = goal["emoji"].toString();
                            });
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "View selected goal",
                      onPressed: _openSelectedGoal,
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BankSafetyScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff111B3C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Razorpay Test Mode simulates a payment. It does not move real money or add withdrawable bank funds.",
                          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Test payment: the demo goal balance updates only after Razorpay confirms the payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              const SizedBox(height: 10),
              GradientButton(
                text: _isSubmitting ? "Waiting for Razorpay..." : "Pay ₹$selectedAmount with Razorpay",
                onTap: _handleConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Updated Login Screen matching app theme completely and Apple button removed
class PlaceholderLoginScreen extends StatefulWidget {
  const PlaceholderLoginScreen({super.key});

  @override
  State<PlaceholderLoginScreen> createState() => _PlaceholderLoginScreenState();
}

class _PlaceholderLoginScreenState extends State<PlaceholderLoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C), // App theme background color
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Get started free",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xff0A0F1D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Get started free.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Create your account to start saving.",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xff131B31),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Your name",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xff131B31),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xff131B31),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Use at least 8 characters with uppercase, lowercase, and a number.",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff22C55E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Or sign up with",
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2F7BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text("G", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(width: 10),
                              Text(
                                "Sign in with Google",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
