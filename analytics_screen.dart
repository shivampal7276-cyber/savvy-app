import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_session.dart';
import '../transaction_store.dart';
import 'goal_data_store.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _background = Color(0xff040A1C);
  static const _panel = Color(0xff0E162F);
  static const _accent = Colors.cyanAccent;
  static const _pollingInterval = Duration(seconds: 15);

  Map<String, dynamic>? _analytics;
  Object? _loadError;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _loading = true;
  bool _requestInFlight = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _refreshTimer = Timer.periodic(_pollingInterval, (_) => _loadAnalytics());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      final signedIn = await AuthSession.isSignedIn;
      final result = signedIn ? _buildLocalAnalytics() : _emptyAnalytics();
      if (!mounted) return;
      setState(() {
        _signedIn = signedIn;
        _analytics = result;
        _loadError = null;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    } finally {
      _requestInFlight = false;
    }
  }

  Map<String, dynamic> _emptyAnalytics() {
    final now = DateTime.now();
    return {
      'transactionCount': 0,
      'depositTotal': 0,
      'withdrawalTotal': 0,
      'netMovement': 0,
      'currentBalance': 0,
      'thisMonthDeposits': 0,
      'lastMonthDeposits': 0,
      'weeklyDeposits': _weeklyBuckets(const <Map<String, dynamic>>[]),
      'updatedAt': now.toIso8601String(),
    };
  }

  Map<String, dynamic> _buildLocalAnalytics() {
    final now = DateTime.now();
    final transactions = TransactionStore().transactions;
    final deposits = transactions.where((transaction) => transaction['isDeposit'] == true).toList();
    final withdrawals = transactions.where((transaction) => transaction['isDeposit'] == false).toList();
    final depositTotal = deposits.fold<int>(0, (sum, transaction) => sum + _transactionAmount(transaction));
    final withdrawalTotal = withdrawals.fold<int>(0, (sum, transaction) => sum + _transactionAmount(transaction));
    final currentBalance = GoalDataStore().goals.fold<int>(
      0,
      (sum, goal) => sum + ((goal['current'] as num?)?.round() ?? 0),
    );
    final monthStart = DateTime(now.year, now.month);
    final previousMonthStart = DateTime(now.year, now.month - 1);
    final thisMonthDeposits = _sumDeposits(
      deposits,
      (date) => !date.isBefore(monthStart) && date.isBefore(now.add(const Duration(seconds: 1))),
    );
    final lastMonthDeposits = _sumDeposits(
      deposits,
      (date) => !date.isBefore(previousMonthStart) && date.isBefore(monthStart),
    );

    return {
      'transactionCount': transactions.length,
      'depositTotal': depositTotal,
      'withdrawalTotal': withdrawalTotal,
      'netMovement': currentBalance,
      'currentBalance': currentBalance,
      'thisMonthDeposits': thisMonthDeposits,
      'lastMonthDeposits': lastMonthDeposits,
      'weeklyDeposits': _weeklyBuckets(deposits),
      'updatedAt': now.toIso8601String(),
    };
  }

  int _transactionAmount(Map<String, dynamic> transaction) {
    final digits = transaction['amount']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(digits) ?? 0;
  }

  int _sumDeposits(List<Map<String, dynamic>> deposits, bool Function(DateTime) includeDate) {
    return deposits.fold<int>(0, (sum, transaction) {
      final date = transaction['date'];
      if (date is! DateTime || !includeDate(date)) return sum;
      return sum + _transactionAmount(transaction);
    });
  }

  List<Map<String, dynamic>> _weeklyBuckets(List<Map<String, dynamic>> deposits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(Duration(days: (today.weekday - DateTime.monday) % 7));
    return List.generate(4, (index) {
      final start = currentWeekStart.subtract(Duration(days: (3 - index) * 7));
      final end = start.add(const Duration(days: 7));
      final amount = _sumDeposits(deposits, (date) => !date.isBefore(start) && date.isBefore(end));
      return {
        'label': '${start.day} ${_monthAbbreviation(start.month)}',
        'amount': amount,
      };
    });
  }

  String _monthAbbreviation(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  @override
  Widget build(BuildContext context) {
    final data = _analytics;
    final weekly = _readWeekly(data?['weeklyDeposits']);
    final thisMonth = _readInt(data?['thisMonthDeposits']);
    final lastMonth = _readInt(data?['lastMonthDeposits']);
    final depositTotal = _readInt(data?['depositTotal']);
    final withdrawalTotal = _readInt(data?['withdrawalTotal']);
    final netMovement = _readInt(data?['netMovement']);
    final currentBalance = _readInt(data?['currentBalance']);
    final transactionCount = _readInt(data?['transactionCount']);
    final largestWeek = weekly.fold<int>(0, (largest, week) => week.amount > largest ? week.amount : largest);
    final monthChange = _monthChange(thisMonth, lastMonth);
    final busiestWeek = weekly.isEmpty
        ? null
        : weekly.reduce((a, b) => a.amount >= b.amount ? a : b);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
          color: _accent,
          backgroundColor: _panel,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics & Insights',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Live from your current goals and transaction history',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildConnectionStatus(),
                const SizedBox(height: 18),
                if (_loading && data == null)
                  _buildLoadingState()
                else if (data == null)
                  _buildErrorState()
                else ...[
                  if (transactionCount == 0) ...[
                    _buildEmptyState(),
                    const SizedBox(height: 16),
                  ],
                  _buildBalanceCard(currentBalance),
                  const SizedBox(height: 14),
                  _buildTotalsCard(depositTotal, withdrawalTotal, netMovement),
                  const SizedBox(height: 24),
                  const Text(
                    'Weekly Breakdown',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Confirmed deposits · last four calendar weeks',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var index = 0; index < weekly.length; index++) ...[
                        if (index > 0) const SizedBox(width: 9),
                        _buildWeeklyBar(
                          weekly[index],
                          largestWeek == 0 ? 0 : weekly[index].amount / largestWeek,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Insights',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  _buildInsightCard(
                    icon: Icons.compare_arrows_rounded,
                    iconColor: _accent,
                    title: monthChange.title,
                    description: monthChange.description,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: Colors.amber,
                    title: busiestWeek == null || busiestWeek.amount == 0
                        ? 'No weekly deposits yet'
                        : 'Busiest week started ${busiestWeek.label}',
                    description: busiestWeek == null || busiestWeek.amount == 0
                        ? 'A week will appear here after a deposit is recorded on this device.'
                        : '${_formatRupees(busiestWeek.amount)} in confirmed deposits during that week.',
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.update_rounded,
                    iconColor: Colors.deepPurpleAccent,
                    title: '$transactionCount recorded transaction${transactionCount == 1 ? '' : 's'}',
                    description: _lastUpdated == null
                        ? 'Waiting for an update.'
                        : 'Updated ${_formatTime(_lastUpdated!)}. App data refreshes every 15 seconds.',
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (!_signedIn && !_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, color: Colors.white70, size: 16),
            SizedBox(width: 7),
            Text('Guest mode · starts at ₹0', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    final connected = _analytics != null && _loadError == null;
    final connecting = _loading && _analytics == null;
    final color = connecting
        ? Colors.white70
        : connected
            ? Colors.tealAccent
            : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connecting
                ? Icons.sync_rounded
                : connected
                    ? Icons.account_balance_wallet_outlined
                    : Icons.error_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            connecting
                ? 'Loading account data'
                : connected
                    ? 'Using current app data'
                    : 'Could not read app data',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: _panelDecoration(),
        child: const Column(
          children: [
            CircularProgressIndicator(color: _accent),
            SizedBox(height: 14),
            Text('Loading live analytics…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );

  Widget _buildErrorState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Savings data is unavailable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Your current goals and transaction history could not be read. No sample values are shown.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _loading ? null : _loadAnalytics,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_rounded, color: _accent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No transactions are recorded in this app session yet. The balance above still matches your current goals.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );

  Widget _buildBalanceCard(int amount) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total saved across goals', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _formatRupees(amount),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Current balance', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('This matches the total shown on your dashboard.', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.35)),
          ],
        ),
      );

  Widget _buildTotalsCard(int deposits, int withdrawals, int net) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: _panelDecoration(),
        child: Row(
          children: [
            _buildMetric('All deposits', deposits, Colors.tealAccent),
            _verticalDivider(),
            _buildMetric('Withdrawals', withdrawals, Colors.orangeAccent),
            _verticalDivider(),
            _buildMetric('Current balance', net, net >= 0 ? _accent : Colors.orangeAccent),
          ],
        ),
      );

  Widget _buildMetric(String label, int amount, Color color) => Expanded(
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_compactRupees(amount), style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _verticalDivider() => Container(
        height: 34,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        color: Colors.white12,
      );

  Widget _buildWeeklyBar(_WeekTotal week, double heightFactor) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: _panelDecoration(radius: 16),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_compactRupees(week.amount), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 12,
                    height: 80 * heightFactor,
                    decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(fit: BoxFit.scaleDown, child: Text(week.label, style: const TextStyle(color: Colors.white54, fontSize: 10))),
            ],
          ),
        ),
      );

  Widget _buildInsightCard({required IconData icon, required Color iconColor, required String title, required String description}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      );

  BoxDecoration _panelDecoration({double radius = 20}) => BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      );

  List<_WeekTotal> _readWeekly(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((entry) => _WeekTotal(
      entry['label']?.toString() ?? '',
      _readInt(entry['amount']),
    )).toList();
  }

  int _readInt(dynamic value) => value is num ? value.round() : int.tryParse(value?.toString() ?? '') ?? 0;

  _MonthChange _monthChange(int current, int previous) {
    if (previous == 0) {
      if (current == 0) return const _MonthChange('No history', 'There are no prior-month deposits to compare yet.');
      return _MonthChange('New activity', 'This device recorded ${_formatRupees(current)} in deposits this month and none last month.');
    }
    final percent = (((current - previous) / previous) * 100).round();
    if (percent == 0) return _MonthChange('0%', 'Deposits match last month at ${_formatRupees(current)}.');
    final direction = percent > 0 ? 'up' : 'down';
    return _MonthChange(
      '${percent > 0 ? '↑' : '↓'} ${percent.abs()}%',
      'Deposits are ${percent.abs()}% $direction versus ${_formatRupees(previous)} last month.',
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  String _formatRupees(int value) => '₹${_groupIndian(value)}';

  String _compactRupees(int value) {
    if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    return '₹$value';
  }

  String _groupIndian(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return '${value < 0 ? '-' : ''}$digits';
    final lastThree = digits.substring(digits.length - 3);
    var prefix = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (prefix.length > 2) {
      groups.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    groups.insert(0, prefix);
    return '${value < 0 ? '-' : ''}${groups.join(',')},$lastThree';
  }
}

class _WeekTotal {
  const _WeekTotal(this.label, this.amount);
  final String label;
  final int amount;
}

class _MonthChange {
  const _MonthChange(this.badge, this.description) : title = badge;
  final String badge;
  final String title;
  final String description;
}

