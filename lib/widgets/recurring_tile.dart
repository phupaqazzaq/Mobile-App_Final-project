import 'package:flutter/material.dart';

import '../models/recurring_payment.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';

/// One item in the Recurring tab: the category icon, the name, the next
/// payment date, and the amount and billing cycle on the right. Subscriptions
/// also show their yearly cost. Tapping it calls [onTap].
class RecurringTile extends StatelessWidget {
  const RecurringTile({super.key, required this.item, required this.onTap});

  final RecurringPayment item;

  /// Called when the item is tapped (the screen opens the edit form).
  final VoidCallback onTap;

  /// The second line, e.g. "Next: 10 Nov 2026 (in 5 days)".
  String _nextPaymentText() {
    if (!item.isActive) return 'Inactive';

    final today = DateTime.now();
    final days = item.daysUntilNextPayment(today);
    final when = switch (days) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };
    return 'Next: ${formatDate(item.nextPaymentDate(today))} ($when)';
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryFor(item.category);
    final textTheme = Theme.of(context).textTheme;
    final isSubscription = item.type == RecurringPayment.subscription;

    return Opacity(
      opacity: item.isActive ? 1 : 0.5, // inactive items look faded
      child: ListTile(
        onTap: onTap,
        isThreeLine: isSubscription,
        leading: CircleAvatar(
          backgroundColor: category.color,
          foregroundColor: Colors.white,
          child: Icon(category.icon),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          isSubscription
              ? '${_nextPaymentText()}\n${formatBaht(item.yearlyCost)} a year'
              : _nextPaymentText(),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatBaht(item.amount),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              item.billingCycle == RecurringPayment.yearly
                  ? 'per year'
                  : 'per month',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
