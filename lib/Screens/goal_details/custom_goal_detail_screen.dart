import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomGoalDetailScreen extends StatefulWidget {
  final String goalTitle;
  final String emoji;
  final String targetAmount;
  final Function(String) onAmountUpdated;
  final VoidCallback onDeleteGoal;

  const CustomGoalDetailScreen({
    super.key,
    required this.goalTitle,
    required this.emoji,
    required this.targetAmount,
    required this.onAmountUpdated,
    required this.onDeleteGoal,
  });

  @override
  State<CustomGoalDetailScreen> createState() => _CustomGoalDetailScreenState();
}

class _CustomGoalDetailScreenState extends State<CustomGoalDetailScreen> {
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.goalTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Delete button in the app bar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              // Show confirmation dialog before deleting
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xff111B3C),
                  title: const Text("Delete Goal", style: TextStyle(color: Colors.white)),
                  content: Text(
                    "Are you sure you want to delete '${widget.goalTitle}'?",
                    style: const TextStyle(color: Colors.white60),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel", style: TextStyle(color: Colors.cyanAccent)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close dialog
                        widget.onDeleteGoal(); // Trigger delete callback
                        Navigator.pop(context); // Go back to goal screen
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                "Your savings goal for ${widget.goalTitle}.",
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text(
                "YOUR TARGET",
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Text(
                      "₹",
                      style: TextStyle(
                        fontSize: 28,
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
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Save Changes Button
              GestureDetector(
                onTap: () {
                  final newAmount = _amountController.text.trim();
                  widget.onAmountUpdated(newAmount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Goal updated: ₹$newAmount! 🎉"),
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
                      "Save Changes",
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