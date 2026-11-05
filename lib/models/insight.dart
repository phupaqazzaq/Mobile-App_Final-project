/// How urgent a suggestion is, from least to most urgent.
enum InsightSeverity { info, warning, alert }

/// Which picture a suggestion shows. This is a plain enum instead of a Flutter
/// icon so that the insight service stays free of Flutter.
/// lib/widgets/insight_card.dart turns it into a real icon.
enum InsightIcon {
  topCategory,
  overBudget,
  nearBudget,
  projectedOverspend,
  risingCategory,
  subscription,
  fixedCost,
  noBudget,
}

/// One suggestion from the insight service, shown as a card to the user.
class Insight {
  const Insight({
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
  });

  final String title;
  final String message;
  final InsightSeverity severity;
  final InsightIcon icon;
}
