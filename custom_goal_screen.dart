import 'package:flutter/material.dart';

class CustomGoalScreen extends StatefulWidget {
  final Function(Map<String, String>) onGoalCreated;

  const CustomGoalScreen({super.key, required this.onGoalCreated});

  @override
  State<CustomGoalScreen> createState() => _CustomGoalScreenState();
}

class _CustomGoalScreenState extends State<CustomGoalScreen> {
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();

  // Target Date State
  bool isTargetDateEnabled = true;
  DateTime selectedTargetDate = DateTime(2026, 12, 23);

  // Reminders State
  bool isReminderEnabled = true;
  String selectedFrequency = 'Weekly';
  String selectedWeekday = 'Sunday';

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  // Helper function to format DateTime to "23 Dec 2026"
  String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Function to open Date Picker dialog
  void _pickTargetDate() async {
    if (!isTargetDateEnabled) return;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTargetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        selectedTargetDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Create Custom Goal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What are you saving for?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your custom goal name and target amount.",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text(
                "Goal Name",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _goalNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g., Bike",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xff111B3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Target Amount",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g., 50000",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xff111B3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- TARGET DATE SECTION ---
              const Text(
                "TARGET DATE",
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Set a target date", style: TextStyle(fontSize: 15, color: Colors.white)),
                        Switch(
                          value: isTargetDateEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.green,
                          onChanged: (value) {
                            setState(() => isTargetDateEnabled = value);
                          },
                        ),
                      ],
                    ),
                    if (isTargetDateEnabled) ...[
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTargetDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Target", style: TextStyle(fontSize: 15, color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1E294B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatFullDate(selectedTargetDate),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- REMINDERS SECTION ---
              const Text(
                "REMINDERS",
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff111B3C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Remind me to save", style: TextStyle(fontSize: 15, color: Colors.white)),
                        Switch(
                          value: isReminderEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.green,
                          onChanged: (value) {
                            setState(() => isReminderEnabled = value);
                          },
                        ),
                      ],
                    ),
                    if (isReminderEnabled) ...[
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Frequency", style: TextStyle(fontSize: 15, color: Colors.white)),
                            DropdownButton<String>(
                              value: selectedFrequency,
                              dropdownColor: const Color(0xff111B3C),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.unfold_more, color: Colors.white60),
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              items: ['Weekly', 'Monthly', 'Daily'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedFrequency = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Weekday", style: TextStyle(fontSize: 15, color: Colors.white)),
                            DropdownButton<String>(
                              value: selectedWeekday,
                              dropdownColor: const Color(0xff111B3C),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.unfold_more, color: Colors.white60),
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              items: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedWeekday = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  final name = _goalNameController.text.trim();
                  final amount = _targetAmountController.text.trim();

                  if (name.isNotEmpty) {
                    widget.onGoalCreated({
                      "emoji": "🎯",
                      "title": name,
                      "targetAmount": amount,
                    });
                    Navigator.pop(context);
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
                        Color(0xff8A6EFF),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Save Goal",
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