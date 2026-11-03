import 'package:flutter/material.dart';
import 'transaction_details_screen.dart';
import '../transaction_store.dart'; // Import the global transaction store

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Deposits", "Round-ups", "Withdrawals"];

  @override
  Widget build(BuildContext context) {
    // Access the shared global transaction list dynamically
    final allTransactions = TransactionStore().transactions;

    List<Map<String, dynamic>> filteredList = allTransactions.where((tx) {
      if (_selectedFilterIndex == 1) return tx["isDeposit"] == true;
      if (_selectedFilterIndex == 2) return (tx["subtitle"] as String).toLowerCase().contains("round-up");
      if (_selectedFilterIndex == 3) return tx["isPositive"] == false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar / Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Header Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                "Transaction history",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                "Every rupee, accounted for.",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // Filter Pills Horizontal List
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? null : const Color(0xff111B3C),
                          gradient: isSelected
                              ? const LinearGradient(colors: [Color(0xff2F7BFF), Color(0xff24D6FF)])
                              : null,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Transaction List
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                child: Text(
                  "No transactions yet.",
                  style: TextStyle(color: Colors.white38, fontSize: 15),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(22),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final tx = filteredList[index];
                  bool showSectionHeader = index == 0 || filteredList[index - 1]["section"] != tx["section"];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSectionHeader) ...[
                        if (index > 0) const SizedBox(height: 16),
                        Text(
                          tx["section"] ?? "TODAY",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // Tappable card opening TransactionDetailsScreen
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailsScreen(
                                transaction: tx,
                                onDelete: () {
                                  setState(() {});
                                },
                                onUpdate: (updatedTx) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xff111B3C),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1A254B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  (tx["subtitle"] as String? ?? "").toLowerCase().contains("round-up")
                                      ? Icons.sync_rounded
                                      : Icons.savings_rounded,
                                  color: Colors.cyanAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx["title"] ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tx["subtitle"] ?? "",
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                tx["amount"] ?? "",
                                style: TextStyle(
                                  color: (tx["isPositive"] == true) ? Colors.tealAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}