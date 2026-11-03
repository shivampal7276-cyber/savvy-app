import 'package:flutter/material.dart';
import 'goal_screen.dart';
import 'add_money_screen.dart';
import 'withdrawmoneyscreen.dart'; // <--- Withdraw screen import added
import 'transaction_history_screen.dart';
import 'share_progress_screen.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'account_auth_screen.dart';
import 'bank_account_screen.dart';
import '../services/auth_session.dart';
import '../services/linked_bank_store.dart';
import 'notification_screen.dart';
import '../Widgets/savvy_bottom_nav.dart';
import 'goal_data_store.dart';
import '../transaction_store.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? successMessage;

  const HomeScreen({
    super.key,
    this.userName = "User",
    this.userEmail = "user@gmail.com",
    this.successMessage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GoalDataStore _goalStore = GoalDataStore();

  bool _isLoggedIn = false;
  String _activeUserName = 'User';
  String _activeUserEmail = 'user@gmail.com';

  // UPI Link state variables added here
  bool _isUpiLinked = false;
  String _linkedUpiId = "";

  @override
  void initState() {
    super.initState();
    _restoreSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = widget.successMessage;
      if (message != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  Future<void> _restoreSession() async {
    final signedIn = await AuthSession.isSignedIn;
    final savedName = await AuthSession.name;
    final savedEmail = await AuthSession.email;
    if (!mounted) return;
    setState(() {
      _isLoggedIn = signedIn;
      _activeUserName = widget.userName == 'User' ? (savedName ?? 'User') : widget.userName;
      _activeUserEmail = widget.userEmail == 'user@gmail.com' ? (savedEmail ?? 'user@gmail.com') : widget.userEmail;
    });
  }

  void _openSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openBankSafetyScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BankAccountScreen()),
    );
  }

  Future<bool> _requestAuthentication(BuildContext context) async {
    if (await AuthSession.isSignedIn) {
      final name = await AuthSession.name;
      final email = await AuthSession.email;
      if (!mounted) return false;
      setState(() {
        _isLoggedIn = true;
        _activeUserName = name ?? widget.userName;
        _activeUserEmail = email ?? widget.userEmail;
      });
      return true;
    }
    final wantsLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff0E162F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text("🔒", style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text(
              "Login Required",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "You need to be logged in to add money to your goals and track your savings securely.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Login Now", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (!mounted || wantsLogin != true) return false;
    final authenticated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AccountAuthScreen(returnResultOnSuccess: true)),
    );
    if (!mounted || authenticated != true) return false;
    final name = await AuthSession.name;
    final email = await AuthSession.email;
    if (!mounted) return false;
    setState(() {
      _isLoggedIn = true;
      _activeUserName = name ?? widget.userName;
      _activeUserEmail = email ?? widget.userEmail;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have successfully logged in.')),
    );
    return true;
  }

  void _showLoginRequiredDialog(BuildContext context, {VoidCallback? onAuthenticated}) async {
    final authenticated = await _requestAuthentication(context);
    if (!mounted || !authenticated) return;
    if (onAuthenticated != null) {
      onAuthenticated();
    } else {
      _openAddMoneyScreen(context);
    }
  }

  // Link UPI Dialog Function
  void _showLinkUpiDialog(BuildContext context) {
    final TextEditingController upiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0E162F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Link UPI ID",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your UPI ID for instant transfers and zero-friction goal funding.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. username@okhdfc",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xff040A1C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (upiController.text.trim().isNotEmpty) {
                setState(() {
                  _isUpiLinked = true;
                  _linkedUpiId = upiController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("UPI ID successfully linked!")),
                );
              }
            },
            child: const Text("Verify & Link", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAddMoneyScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMoneyScreen(
          goalTitle: "New laptop",
          goalEmoji: "💻",
          isLoggedIn: _isLoggedIn,
          userId: _activeUserEmail,
          userName: _activeUserName,
          launchCheckoutImmediately: false,
        ),
      ),
    );
    await _restoreSession();
  }

  Future<void> _activateRazorpay(BuildContext context) async {
    if (!await _requestAuthentication(context) || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMoneyScreen(
          goalTitle: 'New laptop',
          goalEmoji: '💻',
          isLoggedIn: true,
          userId: _activeUserEmail,
          userName: _activeUserName,
          launchCheckoutImmediately: true,
        ),
      ),
    );
    await _restoreSession();
  }

  // Withdraw screen open karne ka function
  void _openWithdrawScreen(BuildContext context, List<Map<String, dynamic>> goalsList) {
    if (!_isLoggedIn) {
      _showLoginRequiredDialog(context, onAuthenticated: () => _openWithdrawScreen(context, goalsList));
      return;
    }
    if (goalsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No goals found to withdraw from!")),
      );
      return;
    }

    final goal = goalsList.first;
    int currentBalance = goal["current"] as int;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawMoneyScreen(
          goalTitle: goal["title"]!,
          goalEmoji: goal["emoji"]!,
          currentGoalBalance: currentBalance,
          userId: _activeUserEmail,
          userName: _activeUserName,
          isLoggedIn: _isLoggedIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _goalStore.goalsNotifier,
        builder: (context, goalsList, child) {
          final List<Widget> screens = [
            _buildHomeDashboardContent(context, goalsList),
            GoalScreen(
              canCreateGoals: _isLoggedIn,
              onAuthenticationRequired: () => _requestAuthentication(context),
              onGoalCreated: (_) {
                setState(() {});
              },
            ),
            const TransactionHistoryScreen(),
            const AnalyticsScreen(),
            const SettingsScreen(),
          ];
          return screens[_currentIndex];
        },
      ),
      bottomNavigationBar: SavvyBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            _openSettingsScreen(context);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildHomeDashboardContent(BuildContext context, List<Map<String, dynamic>> goalsList) {
    int totalSaved = goalsList.fold(0, (sum, goal) => sum + (goal["current"] as int));
    final streakDays = TransactionStore().getCurrentSavingStreak();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Hey ${_activeUserName}!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text("👋", style: TextStyle(fontSize: 18)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openSettingsScreen(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xff0E162F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xff0E162F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              "Total saved across goals",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "₹$totalSaved",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xff0E162F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🔥", style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    streakDays == 0 ? "Start a save streak" : "$streakDays-day save streak",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ACTION BUTTONS (Add money, New goal, Withdraw, History)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add,
                    label: "Add money",
                    isPrimary: true,
                    onTap: () => _openAddMoneyScreen(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.track_changes_rounded,
                    label: "New goal",
                    isPrimary: false,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalScreen(
                            canCreateGoals: _isLoggedIn,
                            onAuthenticationRequired: () => _requestAuthentication(context),
                            onGoalCreated: (newGoalData) {
                              int parsedTarget = int.tryParse(newGoalData["targetAmount"]?.toString() ?? "0") ?? 0;
                              _goalStore.addNewGoal(
                                newGoalData["emoji"] ?? "🎯",
                                newGoalData["title"] ?? "New Goal",
                                parsedTarget,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.arrow_upward,
                    label: "Withdraw",
                    isPrimary: false,
                    onTap: () => _openWithdrawScreen(context, goalsList),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: "History",
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text(
              "Your goals",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              itemCount: goalsList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final goal = goalsList[index];
                final int current = goal["current"] as int;
                final int target = int.tryParse(goal["target"].toString()) ?? 1;

                double progressValue = target > 0 ? (current.toDouble() / target.toDouble()).clamp(0.0, 1.0) : 0.0;
                String progressText = "${(progressValue * 100).toStringAsFixed(progressValue > 0 && progressValue < 0.01 ? 2 : 0)}%";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShareProgressScreen(
                            goalTitle: goal["title"]!,
                            goalEmoji: goal["emoji"]!,
                            savedAmountText: current.toString(),
                            targetAmountText: target.toString(),
                            daysLeft: "45",
                            userId: _activeUserEmail,
                            userName: _activeUserName,
                          ),
                        ),
                      );
                    },
                    child: _buildGoalProgressCard(
                      emoji: goal["emoji"]!,
                      title: goal["title"]!,
                      current: "₹$current",
                      target: "₹$target",
                      progressText: progressText,
                      progressValue: progressValue,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Tapping this launches the app's Razorpay payment flow.
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _activateRazorpay(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xff0E162F),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xff24D6FF).withValues(alpha: .35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xff102344),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.payments_rounded, color: Color(0xff24D6FF), size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Razorpay Unified Checkout',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Secure payments for UPI, cards & netbanking',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xff24D6FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Activate',
                          style: TextStyle(color: Color(0xff040A1C), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // UPI ID for Instant Transfers Card (Dynamic State Changes)[cite: 6]
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff0E162F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isUpiLinked ? Colors.green.withValues(alpha: 0.4) : Colors.cyanAccent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_isUpiLinked ? Colors.green : Colors.cyanAccent).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isUpiLinked ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                      color: _isUpiLinked ? Colors.greenAccent : Colors.cyanAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "UPI ID for Instant Transfers",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isUpiLinked ? _linkedUpiId : "Link your UPI ID (e.g., @okhdfc)",
                          style: TextStyle(
                            color: _isUpiLinked ? Colors.greenAccent : Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _isUpiLinked
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Linked",
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showLinkUpiDialog(context),
                    child: const Text(
                      "Link",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xff0E162F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
            width: isPrimary ? 1.2 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.cyanAccent : Colors.white70,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard({
    required String emoji,
    required String title,
    required String current,
    required String target,
    required String progressText,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff0E162F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      current,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Target: $target",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
