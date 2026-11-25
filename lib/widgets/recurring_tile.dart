import 'package:flutter/material.dart';

import '../models/recurring_payment.dart';
import '../utils/app_style.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import 'category_icon.dart';
import 'money_text.dart';

/// One item in the Recurring tab, on its own white card: the category icon,
/// the name, the next payment date, and the amount and billing cycle on the
/// right. Subscriptions also show their yearly cost. Tapping it calls [onTap].
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
    final isSubscription = item.type == RecurringPayment.subscription;
    // Inactive items look faded: a pale icon and grey text. The text stays
    // dark enough to read.
    final textColor = item.isActive ? AppStyle.ink : AppStyle.muted;

    return Card(
      // Keeps the tap ripple inside the round corners.
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        isThreeLine: isSubscription,
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
        leading: Opacity(
          opacity: item.isActive ? 1 : 0.4,
          child: CategoryIcon(category: category),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isSubscription
              ? '${_nextPaymentText()}\n${formatBaht(item.yearlyCost)} a year'
              : _nextPaymentText(),
          style: const TextStyle(color: AppStyle.muted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MoneyText(
              formatBaht(item.amount),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              decimalsStyle: const TextStyle(
                color: AppStyle.muted,
                fontSize: 13,
              ),
            ),
            Text(
              item.billingCycle == RecurringPayment.yearly
                  ? 'per year'
                  : 'per month',
              style: const TextStyle(color: AppStyle.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
