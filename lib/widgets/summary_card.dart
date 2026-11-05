import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// The card at the top of the Home tab. It shows the total for the current
/// month and how it splits into daily spending and recurring payments.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.dailySpending,
    required this.recurringCost,
    required this.month,
  });

  /// The expenses in [month].
  final double dailySpending;

  /// The monthly cost of the active fixed costs and subscriptions.
  final double recurringCost;

  /// The month the total belongs to (shown as its name, e.g. November 2026).
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent in ${formatMonth(month)}',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatBaht(dailySpending + recurringCost),
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily spending ${formatBaht(dailySpending)} · '
                    'Fixed & subscriptions ${formatBaht(recurringCost)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.account_balance_wallet,
              size: 40,
              color: colors.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
