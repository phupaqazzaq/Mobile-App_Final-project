import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/insight.dart';
import '../models/recurring_payment.dart';
import '../services/insight_service.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/motion.dart';
import '../widgets/insight_card.dart';

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

/// The Insights tab: a pie chart of this month's daily spending with a legend,
/// followed by the suggestion cards.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

/// Loads the chart's totals and the suggestions from the database, and
/// remembers which slice of the chart is tapped.
class _InsightsScreenState extends State<InsightsScreen> {
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Text(
                  formatMonth(_month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_totals.isEmpty) _buildEmptyState() else ..._buildChart(),
                if (_recurringCost > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Plus ${formatBaht(_recurringCost)} in fixed costs and '
                      'subscriptions',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                _buildCards(),
              ],
            ),
    );
  }

  /// The pie chart and its legend (one row per category).
  List<Widget> _buildChart() {
    final grandTotal = _totals.values.fold(0.0, (sum, amount) => sum + amount);
    final entries = _totals.entries.toList();

    return [
      SizedBox(
        height: 260,
        // Pie slices sweep in: PieChart's own implicit animation. Whenever
        // its data changes (from zero to the real values, or a slice tapped),
        // it animates from the old slices to the new ones in 800 ms.
        child: PieChart(
          duration: Motion.duration(context, Motion.pieSweep),
          curve: Motion.curve,
          PieChartData(
            startDegreeOffset: -90, // start the first slice at the top
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            pieTouchData: PieTouchData(touchCallback: _onChartTouched),
            sections: [
              for (var i = 0; i < entries.length; i++)
                _buildSection(entries[i].key, entries[i].value, grandTotal, i),
              // An invisible slice for the rest of the circle. It starts as
              // the whole circle and shrinks to nothing while the real slices
              // grow, so they sweep in from the top.
              PieChartSectionData(
                value: _chartReady ? 0 : grandTotal,
                color: Colors.transparent,
                radius: 70,
                showTitle: false,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < entries.length; i++)
        _buildLegendRow(entries[i].key, entries[i].value, grandTotal, i),
    ];
  }

  /// One slice of the pie, labelled with its percentage of the total.
  PieChartSectionData _buildSection(
    String name,
    double amount,
    double grandTotal,
    int index,
  ) {
    final percent = amount / grandTotal * 100;
    const titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
    );

    return PieChartSectionData(
      // Zero on the first frame, so the slice can grow to its real size.
      value: _chartReady ? amount : 0,
      color: categoryFor(name).color,
      // Tap a slice: the tapped slice is drawn 8 px bigger.
      radius: index == _touchedIndex ? 78 : 70,
      title: '${percent.round()}%',
      // Very thin slices have no room for a label.
      showTitle: percent >= 5,
      // The labels start see-through and fade in while the slices grow.
      titleStyle: _chartReady
          ? titleStyle
          : titleStyle.copyWith(
              color: Colors.white.withValues(alpha: 0),
              shadows: [],
            ),
    );
  }

  /// One legend row: the category's colored icon, name, amount and percentage.
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
      color: category.color.withValues(alpha: isTouched ? 0.15 : 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color,
          foregroundColor: Colors.white,
          child: Icon(category.icon),
        ),
        title: Text(category.name),
        trailing: Text(
          '${formatBaht(amount)} · $percent%',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
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
            child: InsightCard(insight: _insights[i]),
          ),
      ],
    );
  }

  /// Shown instead of the chart when nothing was spent this month.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses this month',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
