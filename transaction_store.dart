class TransactionStore {
  static final TransactionStore _instance = TransactionStore._internal();
  factory TransactionStore() => _instance;
  TransactionStore._internal();

  final List<Map<String, dynamic>> transactions = [];

  void addTransaction({
    required String goalTitle,
    required String amount,
    required bool isDeposit,
  }) {
    transactions.insert(0, {
      "title": isDeposit ? "Saved to $goalTitle" : "Withdrawn from $goalTitle",
      "subtitle": "Manual · Just now",
      "amount": "${isDeposit ? '+' : '-'}₹$amount",
      "isDeposit": isDeposit,
      "section": "TODAY",
      "isPositive": isDeposit,
      "date": DateTime.now(), // Dynamic calculation ke liye date track ki ja rahi hai
    });
  }

  // Dynamic weekly average calculation method
  int getWeeklyAverage(String goalTitle) {
    final goalTransactions = transactions.where((t) =>
    t["isDeposit"] == true && t["title"].toString().contains(goalTitle)
    ).toList();

    if (goalTransactions.isEmpty) return 0;

    int totalDeposited = 0;
    for (var t in goalTransactions) {
      String cleanAmount = t["amount"].toString().replaceAll(RegExp(r'[^0-9]'), '');
      totalDeposited += int.tryParse(cleanAmount) ?? 0;
    }

    DateTime earliestDate = DateTime.now();
    for (var t in goalTransactions) {
      if (t["date"] != null && t["date"] is DateTime) {
        if ((t["date"] as DateTime).isBefore(earliestDate)) {
          earliestDate = t["date"];
        }
      }
    }

    int differenceInDays = DateTime.now().difference(earliestDate).inDays;
    double weeks = (differenceInDays / 7);
    if (weeks < 1) weeks = 1;

    return (totalDeposited / weeks).round();
  }
}