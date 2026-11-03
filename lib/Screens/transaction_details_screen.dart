import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final Function(Map<String, dynamic> updatedTx)? onUpdate;
  final VoidCallback? onDelete;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;

    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Close", style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
                  ),
                  const Text(
                    "Transaction Details",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 40), // Balance layout alignment
                ],
              ),
              const SizedBox(height: 30),

              // Overview Section
              const Text("Overview", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx["amount"] ?? "",
                      style: TextStyle(
                        color: (tx["isPositive"] == true) ? Colors.tealAccent : Colors.redAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white60, size: 14),
                        const SizedBox(width: 8),
                        Text("Date: ${tx["section"] ?? 'TODAY'}", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                    if (tx["subtitle"] != null && (tx["subtitle"] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.note, color: Colors.white60, size: 14),
                          const SizedBox(width: 8),
                          Text("Note: ${tx["subtitle"]}", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ],
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