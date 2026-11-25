import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_style.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/motion.dart';
import 'category_icon.dart';

/// Green below 80% of the limit, orange from 80% to 100%, red above 100%.
/// The bright colors are for the bar; with [forText] it returns darker ones
/// that keep 4.5:1 contrast when used for text.
Color _statusColor(double used, {bool forText = false}) {
  if (used > 1) return forText ? Colors.red.shade900 : Colors.red;
  if (used >= 0.8) return forText ? AppStyle.darkOrange : Colors.orange;
  return forText ? Colors.green.shade900 : Colors.green;
}

/// One category of the Budgets tab, drawn as an "envelope" card. With a
/// budget it shows how much is left of the limit, the share used, a soft fill
/// in the category's color that rises as the budget is used, and a progress
/// bar in the status color. Without a budget it says "No budget set".
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

  /// The envelope's place in the list (0 for the first). Each envelope starts
  /// filling 80 ms after the one before it.
  final int index;

  /// Called when the envelope is tapped (the screen opens the budget dialog).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limit = this.limit;
    if (limit != null) {
      return _Envelope(
        category: category,
        spent: spent,
        limit: limit,
        index: index,
        onTap: onTap,
      );
    }

    // No budget yet: the icon, the name and "No budget set".
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryIcon(category: category, size: 40, circle: true),
              const SizedBox(height: 14),
              Text(category.name, style: _nameStyle),
              const SizedBox(height: 4),
              const Text(
                'No budget set',
                style: TextStyle(color: AppStyle.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The style of the category's name on an envelope.
const TextStyle _nameStyle = TextStyle(
  color: AppStyle.ink,
  fontSize: 15,
  fontWeight: FontWeight.w600,
);

/// The envelope of a category that has a budget.
class _Envelope extends StatefulWidget {
  const _Envelope({
    required this.category,
    required this.spent,
    required this.limit,
    required this.index,
    required this.onTap,
  });

  final ExpenseCategory category;
  final double spent;
  final double limit;
  final int index;
  final VoidCallback onTap;

  @override
  State<_Envelope> createState() => _EnvelopeState();
}

/// Fills the envelope when it first appears, and shakes it once if it is
/// over budget.
class _EnvelopeState extends State<_Envelope>
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

  /// Called when the envelope has finished filling.
  void _onFilled() {
    if (widget.spent > widget.limit && _shake.duration != Duration.zero) {
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final used = widget.spent / widget.limit;
    // What is left can't go below ฿0; going over shows "Over by" instead.
    final left = math.max(0.0, widget.limit - widget.spent);

    // Over-budget nudge: once the envelope has filled, AnimatedBuilder moves
    // it sideways with Transform.translate while _shake runs: up to 4 px each
    // way, two quick swings, 300 ms, then still. It never repeats.
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = 4 * math.sin(_shake.value * 4 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Card(
        // Keeps the soft fill and the tap ripple inside the round corners.
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          // Envelopes fill one by one: TweenAnimationBuilder runs from 0 to
          // how much is used in 600 ms, each envelope 80 ms after the one
          // before. Every frame the soft fill rises with the value, and the
          // bar and the percentage follow it. Their color is worked out from
          // the moving value, so they turn orange at 80% and red past 100%
          // while the envelope fills.
          child: TweenAnimationBuilder<double>(
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
              // The fill and the bar are full at 100%, even if more has
              // been spent.
              final filled = value.clamp(0.0, 1.0);
              return Stack(
                children: [
                  // The soft fill in the category's color, rising from the
                  // bottom. Ink (instead of a plain colored box) lets the tap
                  // ripple show on top of it.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        heightFactor: filled,
                        child: Ink(color: widget.category.pastel),
                      ),
                    ),
                  ),
                  _buildContent(value, filled, left),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The texts and the bar of the envelope, for the animated [value].
  Widget _buildContent(double value, double filled, double left) {
    final overBy = widget.spent - widget.limit;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Puts the bar at the bottom when the envelope next to this one is
        // taller.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryIcon(
                    category: widget.category,
                    size: 40,
                    circle: true,
                  ),
                  const Spacer(),
                  // The share used, on a small off-white pill that shows on
                  // both the white card and the soft fill.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const ShapeDecoration(
                      color: AppStyle.canvas,
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      '${(value * 100).round()}% used',
                      style: TextStyle(
                        color: _statusColor(value, forText: true),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.category.name, style: _nameStyle),
              Text(
                formatWholeBaht(left),
                style: const TextStyle(
                  color: AppStyle.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'left of ${formatWholeBaht(widget.limit)}',
                style: const TextStyle(color: AppStyle.muted, fontSize: 13),
              ),
              if (overBy > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Over by ${formatWholeBaht(overBy)}',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: LinearProgressIndicator(
              value: filled,
              color: _statusColor(value),
              backgroundColor: _statusColor(value).withValues(alpha: 0.2),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
