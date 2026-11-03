import 'package:flutter/material.dart';
import '../transaction_store.dart';

// Simple Singleton Store for Notifications
class NotificationStore {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  final ValueNotifier<List<Map<String, dynamic>>> notificationsNotifier = ValueNotifier([
    {
      "id": "1",
      "icon": "🔥",
      "title": "Save Streak Maintained!",
      "message": "Your saving streak is 0 days. Add funds to start one.",
      "time": "2 hours ago",
      "isRead": false,
    },
    {
      "id": "2",
      "icon": "🎯",
      "title": "Goal Progress Update",
      "message": "You're getting closer to your 'New laptop' target. Add funds today!",
      "time": "Yesterday",
      "isRead": true,
    },
    {
      "id": "3",
      "icon": "🏦",
      "title": "Bank Account Linked",
      "message": "HDFC Bank •• 4821 has been successfully verified and linked.",
      "time": "3 days ago",
      "isRead": true,
    },
  ]);

  void addNotification({required String icon, required String title, required String message, required String time}) {
    final currentList = List<Map<String, dynamic>>.from(notificationsNotifier.value);
    currentList.insert(0, {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "icon": icon,
      "title": title,
      "message": message,
      "time": time,
      "isRead": false,
    });
    notificationsNotifier.value = currentList;
  }

  void removeNotification(String id) {
    final currentList = List<Map<String, dynamic>>.from(notificationsNotifier.value);
    currentList.removeWhere((item) => item["id"] == id);
    notificationsNotifier.value = currentList;
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationStore = NotificationStore();
    final currentStreak = TransactionStore().getCurrentSavingStreak();

    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xff040A1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: notificationStore.notificationsNotifier,
        builder: (context, notifications, child) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet.",
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final isStreakNotification = item["id"] == "1";
              final notificationTitle = isStreakNotification && currentStreak == 0
                  ? "Start a saving streak"
                  : item["title"] as String;
              final notificationMessage = isStreakNotification
                  ? currentStreak == 0
                      ? "No recent deposits yet. Add funds to start your streak."
                      : "You are on a $currentStreak-day saving streak. Keep it up!"
                  : item["message"] as String;
              return Dismissible(
                key: Key(item["id"] ?? index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
                onDismissed: (direction) {
                  notificationStore.removeNotification(item["id"]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Notification removed"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff0E162F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item["isRead"]
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(item["icon"], style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notificationTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  item["time"],
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notificationMessage,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
