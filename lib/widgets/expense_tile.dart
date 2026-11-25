import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/app_style.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import 'category_icon.dart';
import 'money_text.dart';

/// One item in the expense list, on its own white card: the category icon,
/// the title, the category and date and time underneath, and the amount on
/// the right. Tapping it calls [onTap].
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.onTap});

  final Expense expense;

  /// Called when the item is tapped (the home screen opens the edit form).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = categoryFor(expense.category);

    return Card(
      // Keeps the tap ripple inside the round corners.
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
        leading: CategoryIcon(category: category),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${category.name} · ${formatDateTime(expense.date)}',
          style: const TextStyle(color: AppStyle.muted),
        ),
        trailing: MoneyText(
          formatBaht(expense.amount),
          style: const TextStyle(
            color: AppStyle.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          decimalsStyle: const TextStyle(color: AppStyle.muted, fontSize: 13),
        ),
      ),
    );
  }
}
