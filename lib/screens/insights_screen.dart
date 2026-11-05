import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/insight.dart';
import '../models/recurring_payment.dart';
import '../services/insight_service.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
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

/// Loads the chart's totals and the suggestions from the database.
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
                for (final insight in _insights) InsightCard(insight: insight),
              ],
            ),
    );
  }

  /// The pie chart and its legend (one row per category).
  List<Widget> _buildChart() {
    final grandTotal = _totals.values.fold(0.0, (sum, amount) => sum + amount);

    return [
      SizedBox(
        height: 260,
        child: PieChart(
          PieChartData(
            startDegreeOffset: -90, // start the first slice at the top
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: [
              for (final entry in _totals.entries)
                _buildSection(entry.key, entry.value, grandTotal),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (final entry in _totals.entries)
        _buildLegendRow(entry.key, entry.value, grandTotal),
    ];
  }

  /// One slice of the pie, labelled with its percentage of the total.
  PieChartSectionData _buildSection(
    String name,
    double amount,
    double grandTotal,
  ) {
    final percent = amount / grandTotal * 100;
    return PieChartSectionData(
      value: amount,
      color: categoryFor(name).color,
      radius: 70,
      title: '${percent.round()}%',
      // Very thin slices have no room for a label.
      showTitle: percent >= 5,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
      ),
    );
  }

  /// One legend row: the category's colored icon, name, amount and percentage.
  Widget _buildLegendRow(String name, double amount, double grandTotal) {
    final category = categoryFor(name);
    final percent = (amount / grandTotal * 100).round();
    return ListTile(
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
