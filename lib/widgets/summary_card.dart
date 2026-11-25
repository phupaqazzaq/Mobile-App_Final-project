import 'package:flutter/material.dart';

import '../utils/app_style.dart';
import '../utils/formatters.dart';
import 'rolling_amount.dart';

/// The card at the top of the Home tab. It shows the total for the current
/// month in big numbers, and how it splits into daily spending and recurring
/// payments.
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
    const mutedStyle = TextStyle(
      color: AppStyle.muted,
      fontWeight: FontWeight.w500,
    );
    const partStyle = TextStyle(
      color: AppStyle.ink,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spent in ${formatMonth(month)}',
                    style: const TextStyle(
                      color: AppStyle.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // A round badge with the wallet icon, in NoPoverty's green.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: colors.onPrimaryContainer,
                    size: 22,
                  ),
                ),
              ],
            ),
            // Total rolls up: after every add, edit or delete the total
            // counts from its old value to the new one
            // (TweenAnimationBuilder inside RollingAmount). The baht are big
            // and bold, the decimals smaller and grey.
            RollingAmount(
              amount: dailySpending + recurringCost,
              style: const TextStyle(
                color: AppStyle.ink,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
              decimalsStyle: const TextStyle(
                color: AppStyle.muted,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // The two parts of the total roll the same way. Each has its
            // own line, so the card keeps the same height while the
            // numbers change. (Sharing one line made it wrap part way
            // through the roll, which pushed the rest of Home down.)
            RollingAmount(
              amount: dailySpending,
              prefix: 'Daily spending ',
              style: partStyle,
              prefixStyle: mutedStyle,
            ),
            const SizedBox(height: 6),
            RollingAmount(
              amount: recurringCost,
              prefix: 'Fixed & subscriptions ',
              style: partStyle,
              prefixStyle: mutedStyle,
            ),
          ],
        ),
      ),
    );
  }
}
