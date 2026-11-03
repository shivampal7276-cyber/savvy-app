import 'package:flutter/material.dart';
import '../../Widgets/gradient_button.dart';
import '../share_progress_screen.dart';

class LaptopGoalScreen extends StatefulWidget {
  final String targetAmount; // Accept the dynamic target amount from GoalScreen

  const LaptopGoalScreen({
    super.key,
    required this.targetAmount,
  });

  @override
  State<LaptopGoalScreen> createState() => _LaptopGoalScreenState();
}

class _LaptopGoalScreenState extends State<LaptopGoalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button & Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "New Laptop Goal",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Icon and Subtitle
              const Icon(Icons.laptop, color: Colors.cyanAccent, size: 40),
              const SizedBox(height: 12),
              const Text(
                "Let's save for that high-performance laptop!",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Target Display Box showing the dynamic amount
              const Text("YOUR TARGET", style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  "₹ ${widget.targetAmount}",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const Spacer(),

              // Save Goal Target Button -> Passes dynamic values to ShareProgressScreen
              GradientButton(
                text: "Save Goal Target",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShareProgressScreen(
                        goalTitle: "New laptop",
                        goalEmoji: "💻",
                        savedAmountText: "0",
                        targetAmountText: widget.targetAmount, // Uses the dynamic target
                        daysLeft: "90",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
