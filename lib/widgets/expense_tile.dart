import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/categories.dart';

/// One item in the expense list: the category icon, the title, the category
/// and date underneath, and the amount on the right. Tapping it calls [onTap].
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.onTap});

  final Expense expense;

  /// Called when the item is tapped (the home screen opens the edit form).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = categoryFor(expense.category);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: category.color,
        foregroundColor: Colors.white,
        child: Icon(category.icon),
      ),
      title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${category.name} · ${formatDate(expense.date)}'),
      trailing: Text(
        formatBaht(expense.amount),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
