import 'package:flutter/material.dart';

import '../utils/categories.dart';

/// The card at the top of the home screen that shows the total spent in the
/// current month, e.g. "Spent in November 2026" and "฿1,250.00".
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.total, required this.month});

  /// Total amount spent in [month].
  final double total;

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
                    formatBaht(total),
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
