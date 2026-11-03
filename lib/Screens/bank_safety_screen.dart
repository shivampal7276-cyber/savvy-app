import 'package:flutter/material.dart';
import 'bank_account_screen.dart';

class BankSafetyScreen extends StatefulWidget {
  const BankSafetyScreen({super.key});

  @override
  State<BankSafetyScreen> createState() => _BankSafetyScreenState();
}

class _BankSafetyScreenState extends State<BankSafetyScreen> {
  // UPI ID save karne ke liye state variable
  String? linkedUpiId;

  // UPI Link Dialog
  void _showLinkUpiDialog(BuildContext context) {
    final TextEditingController upiController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff111B3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Row(
            children: [
              Text("⚡", style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                "Link UPI ID",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter your VPA / UPI ID for fast deposits & withdrawals.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: upiController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. username@okhdfcbank",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xff040A1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return "Please enter a valid UPI ID (e.g. name@upi)";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    linkedUpiId = upiController.text.trim();
                  });
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Successfully linked: $linkedUpiId"),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
              child: const Text("Link UPI", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Bank & Security", style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bank Accounts & UPI",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: .25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.payment, color: Colors.cyanAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'To add money, tap Pay on the Add Money screen. Razorpay Checkout opens there, where you can choose an available payment method such as UPI or card. You do not need to sign in to or link a Razorpay account here.',
                        style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Set up payment methods Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Fixed
                      children: [
                        const Text(
                          "Set up payment methods 1/3",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 1. Bank Account Option
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountScreen())),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xff040A1C),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Icon(Icons.account_balance, color: Colors.cyanAccent, size: 28),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Bank account",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "1 account",
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        // 2. RuPay Credit Card Option
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Opening RuPay Credit Card setup...")),
                            );
                          },
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff1D34B8),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, style: BorderStyle.solid), // Fixed
                                    ),
                                    child: const Icon(Icons.credit_card, color: Colors.white, size: 28),
                                  ),
                                  const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.add, size: 14, color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "RuPay credit",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const Text(
                                "card",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                        // 3. UPI Lite Option
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Opening UPI Lite setup...")),
                            );
                          },
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff1D34B8),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, style: BorderStyle.solid), // Fixed
                                    ),
                                    child: const Icon(Icons.bolt, color: Colors.white, size: 28),
                                  ),
                                  const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.add, size: 14, color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "UPI Lite",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Pay PIN-free",
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Modern Sleek UPI Link Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.cyanAccent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "UPI ID for Instant Transfers",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            linkedUpiId ?? "Link your UPI ID (e.g., @okhdfc)",
                            style: TextStyle(
                              color: linkedUpiId != null ? Colors.greenAccent : Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showLinkUpiDialog(context),
                      child: Text(
                        linkedUpiId == null ? "Link" : "Edit",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
