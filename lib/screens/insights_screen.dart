import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/insight.dart';
import '../models/recurring_payment.dart';
import '../services/insight_service.dart';
import '../utils/app_style.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/motion.dart';
import '../widgets/category_icon.dart';
import '../widgets/insight_card.dart';
import '../widgets/rolling_amount.dart';

/// Reads everything the suggestion engine needs from the database and returns
/// its suggestions, most urgent first. The Home tab uses this too, for the top
/// suggestion.
Future<List<Insight>> loadInsights(DateTime today) async {
  final db = DatabaseHelper.instance;
  return const InsightService(tips: categoryTips).generate(
    thisMonth: await db.getCategoryTotals(today),
    // Month 0 is fine: DateTime turns it into December of the previous year.
    lastMonth: await db.getCategoryTotals(
      DateTime(today.year, today.month - 1),
    ),
    budgets: await db.getBudgets(),
    recurring: await db.getRecurring(),
    today: today,
  );
}

/// The Insights tab: a card with a donut chart of this month's daily
/// spending and its legend, followed by the suggestion cards.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

/// Loads the chart's totals and the suggestions from the database, and
/// remembers which slice of the chart is tapped.
class _InsightsScreenState extends State<InsightsScreen> {
  /// The size of the hole in the middle of the donut, and the thickness of
  /// its ring.
  static const double _holeRadius = 74;
  static const double _ringWidth = 26;

  final DateTime _month = DateTime.now();

  /// This month's expenses per category, biggest first. Recurring payments
  /// are not part of the chart.
  Map<String, double> _totals = {};

  /// The monthly cost of the active fixed costs and subscriptions.
  double _recurringCost = 0;

  /// The suggestions, most urgent first.
  List<Insight> _insights = [];

  /// True until the data has been read from the database.
  bool _isLoading = true;

  /// False for the chart's first frame, which draws every slice at zero so
  /// that the slices can sweep in to their real sizes.
  bool _chartReady = false;

  /// The index of the tapped slice, or -1 when no slice is tapped.
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads the totals and suggestions from the database.
  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final totals = await db.getCategoryTotals(_month);
    final recurring = await db.getRecurring();
    final insights = await loadInsights(_month);
    if (!mounted) return;

    setState(() {
      _totals = totals;
      _recurringCost = RecurringPayment.totalMonthlyCost(recurring);
      _insights = insights;
      _isLoading = false;
    });

    // The first frame draws the chart with every slice at zero. This
    // callback runs after that frame and sets the real values, and PieChart
    // animates from one to the other by itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _chartReady = true);
    });
  }

  /// Tapping a slice selects it: the slice grows a little and its legend row
  /// lights up. Tapping it again, or outside the slices, clears the selection.
  void _onChartTouched(FlTouchEvent event, PieTouchResponse? response) {
    if (event is! FlTapUpEvent) return;
    final index = response?.touchedSection?.touchedSectionIndex ?? -1;
    // The last section is the invisible filler, not a category.
    final isCategory = index >= 0 && index < _totals.length;
    setState(() {
      _touchedIndex = isCategory && index != _touchedIndex ? index : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _buildChartCard(),
                const SizedBox(height: 12),
                _buildCards(),
              ],
            ),
    );
  }

  /// The white card with the month, the donut chart and its legend (or the
  /// empty message), and the line about recurring payments.
  Widget _buildChartCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                formatMonth(_month),
                style: const TextStyle(
                  color: AppStyle.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_totals.isEmpty) _buildEmptyState() else ..._buildChart(),
            if (_recurringCost > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Text(
                  'Plus ${formatBaht(_recurringCost)} in fixed costs and '
                  'subscriptions',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppStyle.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The donut chart, with the total in its middle, and its legend (one row
  /// per category).
  List<Widget> _buildChart() {
    final grandTotal = _totals.values.fold(0.0, (sum, amount) => sum + amount);
    final entries = _totals.entries.toList();

    return [
      SizedBox(
        height: 2 * (_holeRadius + _ringWidth + 8) + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pie slices sweep in: PieChart's own implicit animation. Whenever
            // its data changes (from zero to the real values, or a slice
            // tapped), it animates from the old slices to the new ones in
            // 800 ms.
            PieChart(
              duration: Motion.duration(context, Motion.pieSweep),
              curve: Motion.curve,
              PieChartData(
                startDegreeOffset: -90, // start the first slice at the top
                sectionsSpace: 3,
                centerSpaceRadius: _holeRadius,
                pieTouchData: PieTouchData(touchCallback: _onChartTouched),
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    _buildSection(entries[i].key, entries[i].value, i),
                  // An invisible slice for the rest of the circle. It starts
                  // as the whole circle and shrinks to nothing while the real
                  // slices grow, so they sweep in from the top.
                  PieChartSectionData(
                    value: _chartReady ? 0 : grandTotal,
                    color: Colors.transparent,
                    radius: _ringWidth,
                    showTitle: false,
                  ),
                ],
              ),
            ),
            // The total of the chart in the middle of the ring. It counts up
            // with RollingAmount while the slices sweep in. IgnorePointer
            // lets taps through to the chart.
            IgnorePointer(
              child: SizedBox(
                width: 2 * _holeRadius - 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Daily spending',
                      style: TextStyle(color: AppStyle.muted, fontSize: 13),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RollingAmount(
                        amount: grandTotal,
                        style: const TextStyle(
                          color: AppStyle.ink,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        decimalsStyle: const TextStyle(
                          color: AppStyle.muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < entries.length; i++)
        _buildLegendRow(entries[i].key, entries[i].value, grandTotal, i),
    ];
  }

  /// One slice of the donut, in the category's color. The percentages are
  /// in the legend under the chart.
  PieChartSectionData _buildSection(String name, double amount, int index) {
    return PieChartSectionData(
      // Zero on the first frame, so the slice can grow to its real size.
      value: _chartReady ? amount : 0,
      color: categoryFor(name).color,
      // Tap a slice: the tapped slice is drawn 8 px thicker.
      radius: index == _touchedIndex ? _ringWidth + 8 : _ringWidth,
      showTitle: false,
    );
  }

  /// One legend row: the category's icon, name, amount and percentage.
  Widget _buildLegendRow(
    String name,
    double amount,
    double grandTotal,
    int index,
  ) {
    final category = categoryFor(name);
    final percent = (amount / grandTotal * 100).round();
    final isTouched = index == _touchedIndex;

    // The legend row of the tapped slice lights up in the category's color.
    // AnimatedContainer fades its background color in and out in 250 ms.
    return AnimatedContainer(
      duration: Motion.duration(context, Motion.highlight),
      curve: Motion.curve,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: isTouched ? 0.15 : 0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CategoryIcon(category: category, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: AppStyle.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${formatBaht(amount)} · $percent%',
            style: const TextStyle(color: AppStyle.ink, fontSize: 15),
          ),
        ],
      ),
    );
  }

  /// Suggestion cards slide up: each card fades in and slides up 16 px in
  /// 400 ms, starting 100 ms after the card above it (TweenAnimationBuilder,
  /// with an Interval curve for the delay). The cards sit in one Column so
  /// they all start when the tab opens, not when they are scrolled to.
  Widget _buildCards() {
    return Column(
      children: [
        for (var i = 0; i < _insights.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Motion.duration(
              context,
              Motion.cardStagger * i + Motion.card,
            ),
            curve: Motion.staggered(i, Motion.cardStagger, Motion.card),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InsightCard(insight: _insights[i]),
            ),
          ),
      ],
    );
  }

  /// Shown instead of the chart when nothing was spent this month.
  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 72, color: AppStyle.muted),
          SizedBox(height: 16),
          Text(
            'No expenses this month',
            style: TextStyle(
              color: AppStyle.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
