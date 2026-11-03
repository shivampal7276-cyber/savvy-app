import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../Widgets/gradient_button.dart';
import 'add_money_screen.dart';
import '../transaction_store.dart';

class ShareProgressScreen extends StatefulWidget {
  final String goalTitle;
  final String goalEmoji;
  final String savedAmountText;
  final String targetAmountText;
  final String daysLeft;
  final String userId;
  final String userName;

  const ShareProgressScreen({
    super.key,
    this.goalTitle = "New phone",
    this.goalEmoji = "📱",
    this.savedAmountText = "0",
    this.targetAmountText = "30000",
    this.daysLeft = "45",
    this.userId = "demo-user",
    this.userName = "Savyyk user",
  });

  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  late double savedNum;
  late double targetNum;
  int _totalAddedWhileHere = 0;

  @override
  void initState() {
    super.initState();
    savedNum = double.tryParse(widget.savedAmountText.replaceAll(',', '')) ?? 0.0;
    targetNum = double.tryParse(widget.targetAmountText.replaceAll(',', '')) ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    double progressValue = targetNum > 0 ? (savedNum / targetNum) : 0.0;
    if (progressValue > 1.0) progressValue = 1.0;
    if (progressValue < 0.0) progressValue = 0.0;

    double exactPercentage = progressValue * 100;

    final String calculatedPercentage = (exactPercentage < 1 && exactPercentage > 0)
        ? "${exactPercentage.toStringAsFixed(2)}%"
        : "${exactPercentage.toInt()}%";

    int percentageInt = exactPercentage.toInt();

    int baseDays = int.tryParse(widget.daysLeft) ?? 45;
    int dynamicDaysLeft = ((1.0 - progressValue) * baseDays).clamp(0, baseDays).toInt();

    final transactionStore = TransactionStore();
    final int streak = transactionStore.getCurrentSavingStreak();
    final int dynamicAvgWeekly = transactionStore.getWeeklyAverage(widget.goalTitle);

    bool isAt0 = percentageInt < 25;
    bool isAt25 = percentageInt >= 25 && percentageInt < 50;
    bool isAt50 = percentageInt >= 50 && percentageInt < 75;
    bool isAt75 = percentageInt >= 75 && percentageInt < 100;
    bool isAt100 = percentageInt >= 100;

    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Back Button & Title
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context, {
                                "savedAmount": savedNum.toInt(),
                                "goalTitle": widget.goalTitle,
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${widget.goalEmoji} ${widget.goalTitle}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Professional Thick Gradient Circular Progress Indicator Container
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(180, 180),
                                painter: GradientCircularProgressPainter(
                                  progress: progressValue,
                                  strokeWidth: 14,
                                  backgroundColor: const Color(0xff111B3C),
                                  gradientColors: const [
                                    Color(0xff24D6FF),
                                    Color(0xff2F7BFF),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    calculatedPercentage,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${savedNum.toStringAsFixed(0)} of ₹${targetNum.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff111B3C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildStatItem("$dynamicDaysLeft", "days to goal", Colors.cyanAccent)),
                            Container(height: 30, width: 1, color: Colors.white12),
                            Expanded(child: _buildStatItem("₹$dynamicAvgWeekly", "avg / week", Colors.white)),
                            Container(height: 30, width: 1, color: Colors.white12),
                            Expanded(child: _buildStatItem(streak.toString(), "day streak", Colors.amber)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Milestones Section Title
                      const Text(
                        "Milestones",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Milestones mapped to actual progress
                      _buildMilestoneItem(
                        isCompleted: percentageInt > 0 || savedNum > 0,
                        isCurrent: isAt0,
                        title: "Goal created",
                        subtitle: savedNum > 0 ? "Started saving" : "Started with ₹0 saved",
                      ),
                      _buildMilestoneItem(
                        isCompleted: percentageInt >= 25,
                        isCurrent: isAt25,
                        title: "25% reached",
                        subtitle: percentageInt >= 25 ? "Milestone unlocked!" : "Target: 25%",
                      ),
                      _buildMilestoneItem(
                        isCompleted: percentageInt >= 50,
                        isCurrent: isAt50,
                        title: "50% reached",
                        subtitle: percentageInt >= 50 ? "Halfway there!" : "Target: 50%",
                      ),
                      _buildMilestoneItem(
                        isCompleted: percentageInt >= 75,
                        isCurrent: isAt75,
                        title: "75% reached",
                        subtitle: percentageInt >= 75 ? "Almost finished!" : "Target: 75%",
                      ),
                      _buildMilestoneItem(
                        isCompleted: percentageInt >= 100,
                        isCurrent: isAt100,
                        title: "Goal complete",
                        subtitle: percentageInt >= 100 ? "Successfully achieved! 🎉" : "Est. completion soon",
                        isLast: true,
                      ),

                      const Spacer(),
                      const SizedBox(height: 20),

                      // Boost this goal Button
                      GradientButton(
                        text: "Boost this goal",
                        onTap: () async {
                          final result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMoneyScreen(
                                goalTitle: widget.goalTitle,
                                goalEmoji: widget.goalEmoji,
                                userId: widget.userId,
                                userName: widget.userName,
                              ),
                            ),
                          );

                          if (result != null && mounted) {
                            setState(() {
                              int addedAmount = result["savedAmount"] ?? 0;
                              savedNum += addedAmount;
                              _totalAddedWhileHere += addedAmount;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMilestoneItem({
    bool isCompleted = false,
    bool isCurrent = false,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    bool activeIndicator = isCompleted || isCurrent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.cyanAccent : Colors.transparent,
                  border: Border.all(
                    color: activeIndicator ? Colors.cyanAccent : Colors.white30,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Center(
                  child: Icon(Icons.check, size: 8, color: Colors.black),
                )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.cyanAccent : Colors.white12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrent ? "$title — you're here" : title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.cyanAccent : (isCompleted ? Colors.white : Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final List<Color> gradientColors;

  GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas sizeCanvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    sizeCanvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return;

    Rect rect = Rect.fromCircle(center: center, radius: radius);
    SweepGradient gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: gradientColors,
      tileMode: TileMode.clamp,
    );

    Paint progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double sweepAngle = 2 * math.pi * progress;
    sizeCanvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
