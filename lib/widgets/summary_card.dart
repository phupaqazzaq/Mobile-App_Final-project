import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'rolling_amount.dart';

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
    final smallStyle = textTheme.bodySmall?.copyWith(
      color: colors.onPrimaryContainer,
    );

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
                  // Total rolls up: after every add, edit or delete the total
                  // counts from its old value to the new one
                  // (TweenAnimationBuilder inside RollingAmount).
                  RollingAmount(
                    amount: dailySpending + recurringCost,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // The two parts of the total roll the same way. Each has its
                  // own line, so the card keeps the same height while the
                  // numbers change. (Sharing one line made it wrap part way
                  // through the roll, which pushed the rest of Home down.)
                  RollingAmount(
                    amount: dailySpending,
                    prefix: 'Daily spending ',
                    style: smallStyle,
                  ),
                  RollingAmount(
                    amount: recurringCost,
                    prefix: 'Fixed & subscriptions ',
                    style: smallStyle,
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
