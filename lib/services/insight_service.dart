import '../models/insight.dart';
import '../models/recurring_payment.dart';
import '../utils/formatters.dart';

/// The suggestion engine: eight simple rules that turn this month's numbers
/// into advice. It uses no database and no Flutter, only plain Dart, so every
/// rule can be unit tested (see test/insight_service_test.dart).
class InsightService {
  const InsightService({required this.tips});

  /// Two spending tips per category. They are defined in
  /// lib/utils/categories.dart, which uses Flutter, so the screens pass them in.
  final Map<String, List<String>> tips;

  /// Runs all the rules and returns the suggestions, most urgent first.
  ///
  /// [thisMonth] and [lastMonth] are the totals per category from the expenses
  /// table, [budgets] holds the monthly limit per category, and [recurring] is
  /// every fixed cost and subscription.
  List<Insight> generate({
    required Map<String, double> thisMonth,
    required Map<String, double> lastMonth,
    required Map<String, double> budgets,
    required List<RecurringPayment> recurring,
    required DateTime today,
  }) {
    final insights = [
      ..._topCategory(thisMonth, today),
      ..._overBudget(thisMonth, budgets, recurring),
      ..._nearBudget(thisMonth, budgets, recurring, today),
      ..._projectedOverspend(thisMonth, budgets, recurring, today),
      ..._risingCategories(thisMonth, lastMonth),
      ..._subscriptionCost(recurring),
      ..._fixedCostShare(thisMonth, recurring),
      ..._noBudgets(budgets),
    ];

    // Alerts first, then warnings, then info. Going through one severity at a
    // time keeps the suggestions of each severity in rule order.
    return [
      for (final severity in InsightSeverity.values.reversed)
        ...insights.where((insight) => insight.severity == severity),
    ];
  }

  /// Rule 1: which category takes the biggest share of daily spending.
  /// Daily spending means the expenses table only, like the pie chart.
  List<Insight> _topCategory(Map<String, double> thisMonth, DateTime today) {
    final total = _sum(thisMonth.values);
    if (total <= 0) return [];

    var top = thisMonth.entries.first;
    for (final entry in thisMonth.entries) {
      if (entry.value > top.value) top = entry;
    }

    final percent = (top.value / total * 100).round();
    var message = '${top.key} is $percent% of your daily spending.';
    // This changes the tip every month but keeps it the same within a month.
    final categoryTips = tips[top.key];
    if (categoryTips != null) {
      message += ' ${categoryTips[(today.month + 1) % 2]}';
    }

    return [
      Insight(
        title: 'Biggest expense',
        message: message,
        severity: InsightSeverity.info,
        icon: InsightIcon.topCategory,
      ),
    ];
  }

  /// Rule 2: categories that have gone over their limit.
  List<Insight> _overBudget(
    Map<String, double> thisMonth,
    Map<String, double> budgets,
    List<RecurringPayment> recurring,
  ) {
    return [
      for (final budget in budgets.entries)
        if (_spent(budget.key, thisMonth, recurring) > budget.value)
          Insight(
            title: 'Over budget',
            message:
                'You are ${formatWholeBaht(_spent(budget.key, thisMonth, recurring) - budget.value)} '
                'over your ${budget.key} budget.',
            severity: InsightSeverity.alert,
            icon: InsightIcon.overBudget,
          ),
    ];
  }

  /// Rule 3: categories that have used at least 80% of their limit but are
  /// not over it yet (rule 2 covers those).
  List<Insight> _nearBudget(
    Map<String, double> thisMonth,
    Map<String, double> budgets,
    List<RecurringPayment> recurring,
    DateTime today,
  ) {
    final daysLeft = _daysInMonth(today) - today.day;
    final insights = <Insight>[];

    for (final budget in budgets.entries) {
      final spent = _spent(budget.key, thisMonth, recurring);
      final used = spent / budget.value;
      if (used < 0.8 || used > 1) continue;

      final percent = (used * 100).round();
      insights.add(
        Insight(
          title: 'Near budget',
          message:
              '$percent% of your ${budget.key} budget is used with '
              '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left.',
          severity: InsightSeverity.warning,
          icon: InsightIcon.nearBudget,
        ),
      );
    }
    return insights;
  }

  /// Rule 4: categories that will go over their limit at the current pace.
  /// The first days of a month say little, so this only starts after day 5.
  List<Insight> _projectedOverspend(
    Map<String, double> thisMonth,
    Map<String, double> budgets,
    List<RecurringPayment> recurring,
    DateTime today,
  ) {
    if (today.day <= 5) return [];

    final insights = <Insight>[];
    for (final budget in budgets.entries) {
      final daily = thisMonth[budget.key] ?? 0;
      if (daily <= 0) continue;

      // The daily average × the days in the month. A category's recurring
      // payments count as spent too, but they don't grow with the pace.
      final projected =
          daily * _daysInMonth(today) / today.day +
          RecurringPayment.totalMonthlyCost(recurring, category: budget.key);
      if (projected <= budget.value) continue;

      insights.add(
        Insight(
          title: 'Projected overspend',
          message:
              "At this pace you'll spend ${formatWholeBaht(projected)} on "
              '${budget.key.toLowerCase()} this month, '
              '${formatWholeBaht(projected - budget.value)} over budget.',
          severity: InsightSeverity.warning,
          icon: InsightIcon.projectedOverspend,
        ),
      );
    }
    return insights;
  }

  /// Rule 5: categories at least 30% and at least ฿300 above last month.
  List<Insight> _risingCategories(
    Map<String, double> thisMonth,
    Map<String, double> lastMonth,
  ) {
    final insights = <Insight>[];
    for (final entry in thisMonth.entries) {
      final last = lastMonth[entry.key] ?? 0;
      // With nothing spent last month there is no percentage to compare.
      if (last <= 0) continue;

      final difference = entry.value - last;
      final rise = difference / last;
      if (rise < 0.3 || difference < 300) continue;

      insights.add(
        Insight(
          title: 'Rising spending',
          message:
              '${entry.key} is up ${(rise * 100).round()}% from last month.',
          severity: InsightSeverity.info,
          icon: InsightIcon.risingCategory,
        ),
      );
    }
    return insights;
  }

  /// Rule 6: what the active subscriptions cost per year.
  List<Insight> _subscriptionCost(List<RecurringPayment> recurring) {
    final active = recurring.where(
      (item) => item.isActive && item.type == RecurringPayment.subscription,
    );
    if (active.isEmpty) return [];

    final yearly = formatWholeBaht(_sum(active.map((item) => item.yearlyCost)));
    return [
      Insight(
        title: 'Subscriptions',
        message: active.length == 1
            ? 'Your 1 subscription costs $yearly a year. '
                  'Cancel it if you no longer use it.'
            : 'Your ${active.length} subscriptions cost $yearly a year. '
                  'Cancel any you no longer use.',
        severity: InsightSeverity.info,
        icon: InsightIcon.subscription,
      ),
    ];
  }

  /// Rule 7: fixed costs taking more than half of this month's total.
  List<Insight> _fixedCostShare(
    Map<String, double> thisMonth,
    List<RecurringPayment> recurring,
  ) {
    final fixed = RecurringPayment.totalMonthlyCost(
      recurring,
      type: RecurringPayment.fixed,
    );
    final total =
        _sum(thisMonth.values) + RecurringPayment.totalMonthlyCost(recurring);
    if (fixed <= total * 0.5) return [];

    return [
      Insight(
        title: 'Fixed costs',
        message:
            'Fixed costs are ${(fixed / total * 100).round()}% of your '
            'spending. Look for a cheaper phone plan or shared housing.',
        severity: InsightSeverity.info,
        icon: InsightIcon.fixedCost,
      ),
    ];
  }

  /// Rule 8: no budgets have been set yet.
  List<Insight> _noBudgets(Map<String, double> budgets) {
    if (budgets.isNotEmpty) return [];

    return const [
      Insight(
        title: 'No budgets yet',
        message: 'Set a budget for your biggest category to start saving.',
        severity: InsightSeverity.info,
        icon: InsightIcon.noBudget,
      ),
    ];
  }

  /// "Spent" for a category: its expenses this month plus the monthly cost of
  /// its recurring payments.
  double _spent(
    String category,
    Map<String, double> thisMonth,
    List<RecurringPayment> recurring,
  ) {
    return (thisMonth[category] ?? 0) +
        RecurringPayment.totalMonthlyCost(recurring, category: category);
  }

  double _sum(Iterable<double> values) {
    return values.fold(0.0, (sum, value) => sum + value);
  }

  /// Day 0 of the next month is the last day of this month.
  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
}
