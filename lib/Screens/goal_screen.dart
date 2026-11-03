import 'package:flutter/material.dart';
import '../Widgets/goal_card.dart';
import 'share_progress_screen.dart';
import 'goal_details/custom_goal_screen.dart';
import 'goal_data_store.dart'; // Import central store

class GoalScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onGoalCreated;
  final bool canCreateGoals;
  final Future<bool> Function()? onAuthenticationRequired;

  const GoalScreen({
    super.key,
    this.onGoalCreated,
    this.canCreateGoals = true,
    this.onAuthenticationRequired,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  int selected = -1; // Fixed: No auto-navigation on load
  bool roundUp = true;
  late bool _canCreateGoals;

  // Instance of central store
  final GoalDataStore _goalStore = GoalDataStore();

  @override
  void initState() {
    super.initState();
    _canCreateGoals = widget.canCreateGoals;
  }

  String _getEstimatedDays(String title) {
    switch (title.toLowerCase()) {
      case 'new laptop':
        return '90';
      case 'new phone':
        return '60';
      case 'goa trip':
        return '120';
      case 'emergency fund':
        return '180';
      default:
        return '90';
    }
  }

  // Dynamic navigation passing the exact clicked goal data
  void _navigateToDetail(int index) async {
    var goal = _goalStore.goals[index];
    String currentAmount = goal["target"].toString();
    String currentSaved = goal["current"].toString();
    String currentTitle = goal["title"] ?? "";
    String currentEmoji = goal["emoji"] ?? "🎯";

    Widget nextScreen = ShareProgressScreen(
      goalTitle: currentTitle,
      goalEmoji: currentEmoji,
      savedAmountText: currentSaved,
      targetAmountText: currentAmount,
      daysLeft: _getEstimatedDays(currentTitle),
    );

    // Wait for the result when coming back from detail/share screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );

    // Agar aage ki screen se koi update ya new saved amount aaya ho toh yahan sync karein
    if (result != null && mounted) {
      setState(() {
        if (result is Map && result.containsKey("savedAmount")) {
          _goalStore.addAmountToGoal(result["goalTitle"], result["savedAmount"]);
        } else if (result is String) {
          _goalStore.goals[index]["target"] = int.tryParse(result) ?? _goalStore.goals[index]["target"];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xff111B3C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "What are you saving for?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Pick one, or set your own goal.",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                itemCount: _goalStore.goals.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  var goal = _goalStore.goals[index];
                  return GoalCard(
                    emoji: goal["emoji"]!,
                    title: goal["title"]!,
                    targetAmount: goal["target"].toString(),
                    selected: selected == index,
                    onTap: () {
                      setState(() {
                        selected = index;
                      });
                      _navigateToDetail(index);
                    },
                  );
                },
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Round up my UPI payments",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "We'll round each payment up and save the change.",
                          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: roundUp,
                    activeThumbColor: Colors.cyanAccent,
                    onChanged: (value) {
                      setState(() => roundUp = value);
                    },
                  )
                ],
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () async {
                  if (!_canCreateGoals) {
                    final authenticated = await widget.onAuthenticationRequired?.call() ?? false;
                    if (!mounted || !authenticated) return;
                    setState(() => _canCreateGoals = true);
                  }

                  final Map<String, dynamic>? newGoal = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomGoalScreen(
                        onGoalCreated: (createdGoal) {
                          Navigator.pop(context, createdGoal);
                        },
                      ),
                    ),
                  );

                  if (newGoal != null && mounted) {
                    setState(() {
                      int parsedTarget = int.tryParse(newGoal["targetAmount"]?.toString() ?? "0") ?? 0;
                      _goalStore.addNewGoal(
                        newGoal["emoji"]?.toString() ?? "🎯",
                        newGoal["title"]?.toString() ?? "Custom Goal",
                        parsedTarget,
                      );
                      selected = _goalStore.goals.length - 1;
                    });

                    if (widget.onGoalCreated != null) {
                      widget.onGoalCreated!(newGoal);
                    }
                  }
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xff2F7BFF),
                        Color(0xff24D6FF),
                        Color(0xff8A6EFF)
                      ],
                     ),
                  ),
                  child: const Center(
                    child: Text(
                      "Create Savings Goal",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
