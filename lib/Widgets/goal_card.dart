import 'package:flutter/material.dart';

class GoalCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String? targetAmount;
  final bool selected;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.emoji,
    required this.title,
    this.targetAmount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff111B3C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.cyanAccent : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              targetAmount != null && targetAmount!.isNotEmpty
                  ? "₹ $targetAmount"
                  : "Popular this month",
              style: TextStyle(
                color: targetAmount != null && targetAmount!.isNotEmpty
                    ? Colors.cyanAccent
                    : Colors.white60,
                fontSize: 13,
                fontWeight: targetAmount != null && targetAmount!.isNotEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}