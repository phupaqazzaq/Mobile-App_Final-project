import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/motion.dart';

/// Green below 80% of the limit, orange from 80% to 100%, red above 100%.
Color _colorFor(double used) {
  if (used > 1) return Colors.red;
  if (used >= 0.8) return Colors.orange;
  return Colors.green;
}

/// One row of the Budgets tab: the category icon and name, "฿spent / ฿limit",
/// and a progress bar. Without a budget it says "No budget set" and has no bar.
class BudgetTile extends StatelessWidget {
  const BudgetTile({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.index,
    required this.onTap,
  });

  final ExpenseCategory category;

  /// This month's expenses plus the monthly cost of recurring payments.
  final double spent;

  /// The monthly limit, or null if this category has no budget.
  final double? limit;

  /// The row's place in the list (0 for the first row). Each row's bar starts
  /// filling 80 ms after the bar of the row above it.
  final int index;

  /// Called when the row is tapped (the screen opens the budget dialog).
  final VoidCallback onTap;

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
      subtitle: limit == null
          ? null
          : _BudgetBar(spent: spent, limit: limit, index: index),
    );
  }
}

/// The progress bar of one budget, plus "Over by ฿X" when the limit has been
/// passed.
class _BudgetBar extends StatefulWidget {
  const _BudgetBar({
    required this.spent,
    required this.limit,
    required this.index,
  });

  final double spent;
  final double limit;
  final int index;

  @override
  State<_BudgetBar> createState() => _BudgetBarState();
}

/// Fills the bar when it first appears, and shakes it once if it is over
/// budget.
class _BudgetBarState extends State<_BudgetBar>
    with SingleTickerProviderStateMixin {
  /// Runs the over-budget shake from 0 to 1, once.
  late final AnimationController _shake = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Duration.zero when animations are turned off: then there is no shake.
    _shake.duration = Motion.duration(context, Motion.shake);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Called when the bar has finished filling.
  void _onFilled() {
    if (widget.spent > widget.limit && _shake.duration != Duration.zero) {
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final used = widget.spent / widget.limit;

    // Over-budget nudge: once the bar has filled, AnimatedBuilder moves it
    // sideways with Transform.translate while _shake runs: up to 4 px each
    // way, two quick swings, 300 ms, then still. It never repeats.
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = 4 * math.sin(_shake.value * 4 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Bars fill one by one: TweenAnimationBuilder runs the bar from 0
          // to how much is used in 600 ms, each row 80 ms after the row
          // above. The color is worked out from the moving value every
          // frame, so the bar turns orange at 80% and red past 100% while it
          // fills.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: used),
            duration: Motion.duration(
              context,
              Motion.barStagger * widget.index + Motion.barFill,
            ),
            curve: Motion.staggered(
              widget.index,
              Motion.barStagger,
              Motion.barFill,
            ),
            onEnd: _onFilled,
            builder: (context, value, child) {
              final color = _colorFor(value);
              return LinearProgressIndicator(
                // The bar is full at 100%, even if more has been spent.
                value: value.clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
              );
            },
          ),
          if (used > 1) ...[
            const SizedBox(height: 4),
            Text(
              'Over by ${formatWholeBaht(widget.spent - widget.limit)}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
