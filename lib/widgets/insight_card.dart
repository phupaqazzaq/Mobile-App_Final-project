import 'package:flutter/material.dart';

import '../models/insight.dart';
import '../utils/app_style.dart';

/// One suggestion on a card tinted with its severity color: a round icon
/// badge and the title on top, the message underneath. The Home tab passes
/// [onSeeAll] to add a "See all" button to its top suggestion.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, this.onSeeAll});

  final Insight insight;

  /// Called when "See all" is tapped. If null, the button is not shown.
  final VoidCallback? onSeeAll;

  /// The card's light tint: blue for info, orange for warning, red for alert.
  Color get _tint => switch (insight.severity) {
    InsightSeverity.info => Colors.blue.shade50,
    InsightSeverity.warning => Colors.orange.shade50,
    InsightSeverity.alert => Colors.red.shade50,
  };

  /// The darker color of the icon and the title, in the same three colors.
  /// They are dark enough to keep 4.5:1 contrast on the tint.
  Color get _accent => switch (insight.severity) {
    InsightSeverity.info => Colors.blue.shade800,
    InsightSeverity.warning => AppStyle.darkOrange,
    InsightSeverity.alert => Colors.red.shade900,
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
    final onSeeAll = this.onSeeAll;

    return Card(
      color: _tint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // A round white badge with the suggestion's icon.
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('See all'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              insight.message,
              style: const TextStyle(color: AppStyle.ink, fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}
