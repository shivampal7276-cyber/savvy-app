class TransactionStore {
  // Singleton pattern to keep data synchronized across all screens
  static final TransactionStore _instance = TransactionStore._internal();
  factory TransactionStore() => _instance;
  TransactionStore._internal();

  // Transactions list (starts completely empty)
  final List<Map<String, dynamic>> transactions = [];

  // Method to add a new transaction dynamically
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
      "date": DateTime.now(),
    });
  }

  int getCurrentSavingStreak({DateTime? now}) {
    final today = now ?? DateTime.now();
    final savingDays = transactions
        .where((transaction) => transaction["isDeposit"] == true)
        .map((transaction) => transaction["date"])
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (savingDays.isEmpty) return 0;
    final latest = savingDays.first;
    final todayDate = DateTime(today.year, today.month, today.day);
    if (todayDate.difference(latest).inDays > 1) return 0;

    var streak = 1;
    for (var i = 1; i < savingDays.length; i++) {
      if (savingDays[i - 1].difference(savingDays[i]).inDays != 1) break;
      streak++;
    }
    return streak;
  }

  int getWeeklyAverage([String? goalTitle]) {
    final deposits = transactions.where((transaction) {
      if (transaction["isDeposit"] != true) return false;
      return goalTitle == null ||
          transaction["title"].toString().toLowerCase().contains(goalTitle.toLowerCase());
    }).toList();
    if (deposits.isEmpty) return 0;

    final total = deposits.fold<int>(0, (sum, transaction) {
      final amount = transaction["amount"].toString().replaceAll(RegExp(r'[^0-9]'), '');
      return sum + (int.tryParse(amount) ?? 0);
    });
    final dates = deposits
        .map((transaction) => transaction["date"])
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return 0;
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final elapsedDays = DateTime.now().difference(earliest).inDays + 1;
    final elapsedWeeks = (elapsedDays / 7).ceil().clamp(1, 52);
    return (total / elapsedWeeks).round();
  }
}
