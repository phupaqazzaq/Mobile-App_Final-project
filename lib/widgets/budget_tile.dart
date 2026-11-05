import 'package:flutter/material.dart';

import '../utils/categories.dart';
import '../utils/formatters.dart';

/// One row of the Budgets tab: the category icon and name, "฿spent / ฿limit",
/// and a progress bar. Without a budget it says "No budget set" and has no bar.
class BudgetTile extends StatelessWidget {
  const BudgetTile({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.onTap,
  });

  final ExpenseCategory category;

  /// This month's expenses plus the monthly cost of recurring payments.
  final double spent;

  /// The monthly limit, or null if this category has no budget.
  final double? limit;

  /// Called when the row is tapped (the screen opens the budget dialog).
  final VoidCallback onTap;

  /// Green below 80% of the limit, orange from 80% to 100%, red above 100%.
  Color _colorFor(double used) {
    if (used > 1) return Colors.red;
    if (used >= 0.8) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final limit = this.limit;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: category.color,
        foregroundColor: Colors.white,
        child: Icon(category.icon),
      ),
      title: Row(
        children: [
          Expanded(child: Text(category.name)),
          Text(
            limit == null
                ? 'No budget set'
                : '${formatWholeBaht(spent)} / ${formatWholeBaht(limit)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      subtitle: limit == null ? null : _buildProgress(limit),
    );
  }

  /// The progress bar, plus "Over by ฿X" when the limit has been passed.
  Widget _buildProgress(double limit) {
    final used = spent / limit;
    final color = _colorFor(used);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          // The bar is full at 100%, even if more has been spent.
          value: used.clamp(0.0, 1.0),
          color: color,
          backgroundColor: color.withValues(alpha: 0.2),
        ),
        if (used > 1) ...[
          const SizedBox(height: 4),
          Text(
            'Over by ${formatWholeBaht(spent - limit)}',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
