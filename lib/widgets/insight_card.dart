import 'package:flutter/material.dart';

import '../models/insight.dart';

/// One suggestion: an icon, a severity color, a title and a message. The Home
/// tab passes [onSeeAll] to add a "See all" link to its top suggestion.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, this.onSeeAll});

  final Insight insight;

  /// Called when "See all" is tapped. If null, the link is not shown.
  final VoidCallback? onSeeAll;

  /// Blue for info, orange for warning, red for alert.
  MaterialColor get _color => switch (insight.severity) {
    InsightSeverity.info => Colors.blue,
    InsightSeverity.warning => Colors.orange,
    InsightSeverity.alert => Colors.red,
  };

  /// Turns the service's plain icon value into a real Flutter icon.
  IconData get _icon => switch (insight.icon) {
    InsightIcon.topCategory => Icons.pie_chart,
    InsightIcon.overBudget => Icons.error,
    InsightIcon.nearBudget => Icons.warning_amber,
    InsightIcon.projectedOverspend => Icons.trending_up,
    InsightIcon.risingCategory => Icons.show_chart,
    InsightIcon.subscription => Icons.subscriptions,
    InsightIcon.fixedCost => Icons.home_work,
    InsightIcon.noBudget => Icons.savings,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: _color.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: _color.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: _color.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(insight.message, style: textTheme.bodyMedium),
                ],
              ),
            ),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
      ),
    );
  }
}
