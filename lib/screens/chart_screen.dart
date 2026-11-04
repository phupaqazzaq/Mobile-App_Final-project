import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../utils/categories.dart';

/// Shows a pie chart of the current month's spending by category, with a
/// legend that lists each category's name and amount.
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final DateTime _month = DateTime.now();

  /// Amount spent per category this month, biggest first.
  Map<String, double> _totals = {};

  /// True until the totals have been read from the database.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  /// Reads this month's per-category totals from the database.
  Future<void> _loadTotals() async {
    final totals = await DatabaseHelper.instance.getCategoryTotals(_month);
    if (!mounted) return;
    setState(() {
      _totals = totals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending Chart')),
      body: _buildBody(),
    );
  }

  /// A spinner while loading, the empty message, or the chart and legend.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_totals.isEmpty) {
      return _buildEmptyState();
    }

    final grandTotal = _totals.values.fold(0.0, (sum, amount) => sum + amount);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          formatMonth(_month),
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        // The legend: one row per category.
        for (final entry in _totals.entries)
          _buildLegendRow(entry.key, entry.value),
        const Divider(),
        ListTile(
          title: Text('Total', style: textTheme.titleMedium),
          trailing: Text(
            formatBaht(grandTotal),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
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

  /// One legend row: the category's colored icon, its name and its amount.
  Widget _buildLegendRow(String name, double amount) {
    final category = categoryFor(name);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.color,
        foregroundColor: Colors.white,
        child: Icon(category.icon),
      ),
      title: Text(category.name),
      trailing: Text(
        formatBaht(amount),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  /// Shown when nothing was spent this month.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
