import 'package:flutter/foundation.dart';

class GoalDataStore {
  static final GoalDataStore _instance = GoalDataStore._internal();
  factory GoalDataStore() => _instance;
  GoalDataStore._internal();

  // Using ValueNotifier so listeners (HomeScreen, AdminScreen) update instantly
  final ValueNotifier<List<Map<String, dynamic>>> goalsNotifier = ValueNotifier([
    {"emoji": "💻", "title": "New laptop", "target": 60000, "current": 0},
    {"emoji": "📱", "title": "New phone", "target": 50000, "current": 0},
    {"emoji": "🌴", "title": "Goa trip", "target": 25000, "current": 0},
    {"emoji": "🛡️", "title": "Emergency fund", "target": 100000, "current": 0},
  ]);

  List<Map<String, dynamic>> get goals => goalsNotifier.value;

  void addAmountToGoal(String title, int amount) {
    final updatedList = List<Map<String, dynamic>>.from(goals);
    for (var goal in updatedList) {
      if (goal["title"].toString().toLowerCase() == title.toLowerCase()) {
        goal["current"] = (goal["current"] as int) + amount;
      }
    }
    goalsNotifier.value = updatedList; // Triggers UI update automatically
  }

  void addNewGoal(String emoji, String title, int target) {
    final updatedList = List<Map<String, dynamic>>.from(goals);
    if (!updatedList.any((g) => g["title"].toString().toLowerCase() == title.toLowerCase())) {
      updatedList.add({
        "emoji": emoji,
        "title": title,
        "target": target,
        "current": 0,
      });
      goalsNotifier.value = updatedList;
    }
  }
}
