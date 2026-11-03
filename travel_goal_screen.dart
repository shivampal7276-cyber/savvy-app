import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TravelGoalScreen extends StatefulWidget {
  final String targetAmount;

  const TravelGoalScreen({super.key, required this.targetAmount});

  @override
  State<TravelGoalScreen> createState() => _TravelGoalScreenState();
}

class _TravelGoalScreenState extends State<TravelGoalScreen> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.targetAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      appBar: AppBar(
        title: const Text("Travel Goal", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flight_takeoff_rounded, size: 50, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              const Text(
                "Where are we flying next? Plan your trip fund.",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 25),
              const Text(
                "YOUR TARGET",
                style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Text(
                      "₹",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final finalAmount = _amountController.text;
                  Navigator.pop(context, finalAmount);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Goal target saved: ₹$finalAmount! 🎉"),
                      backgroundColor: const Color(0xff111B3C),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xff2F7BFF),
                        Color(0xff24D6FF),
                        Color(0xff8A6EFF),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Save Goal Target",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
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