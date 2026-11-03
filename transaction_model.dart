class TransactionItem {
  final String title;
  final String type; // "Deposits", "Round-ups", "Withdrawals"
  final int amount;
  final String time;

  TransactionItem({
    required this.title,
    required this.type,
    required this.amount,
    required this.time,
  });
}

// Global list keeping track of transactions across the app dynamically
class GlobalTransactions {
  // Start with an empty list so no ghost transactions appear on startup
  static final List<TransactionItem> transactions = [];

  static void addTransaction({required String goalTitle, required int amount}) {
    transactions.insert(
      0,
      TransactionItem(
        title: "Saved to $goalTitle",
        type: "Deposits",
        amount: amount,
        time: "Just now",
      ),
    );
  }
}