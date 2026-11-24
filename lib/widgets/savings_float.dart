import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../utils/motion.dart';

/// A small "+฿5,028 a year" label with four coins that float up and fade out
/// over 900 ms. The Recurring tab shows it once over a subscription that was
/// just switched off. It calls [onDone] when it has finished.
class SavingsFloat extends StatefulWidget {
  const SavingsFloat({
    super.key,
    required this.yearlyAmount,
    required this.onDone,
  });

  /// What the subscription would have cost per year.
  final double yearlyAmount;

  /// Called once the label has faded out.
  final VoidCallback onDone;

  @override
  State<SavingsFloat> createState() => _SavingsFloatState();
}

/// Runs the float once, from the moment the label appears.
class _SavingsFloatState extends State<SavingsFloat>
    with SingleTickerProviderStateMixin {
  // How far left (−) or right (+) of the middle each coin is, and how high it
  // rises, in pixels.
  static const _coinOffsets = [-78.0, -36.0, 38.0, 80.0];
  static const _coinRises = [44.0, 62.0, 54.0, 40.0];

  /// Drives the label and the coins from 0 to 1, once.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.savingsFloat,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Savings label: one AnimationController moves the label and the coins up
    // with Transform.translate and fades them out with Opacity.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, label) {
        // How far up everything has floated, from 0 to 1, slowing at the end.
        final rise = Motion.curve.transform(_controller.value);
        return Opacity(
          // Fully visible at first, then fading faster towards the end.
          opacity: 1 - Curves.easeIn.transform(_controller.value),
          child: SizedBox(
            width: 220,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none, // the coins rise above the box
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < _coinOffsets.length; i++)
                  Transform.translate(
                    offset: Offset(_coinOffsets[i], 8 - _coinRises[i] * rise),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, -36 * rise),
                  child: label,
                ),
              ],
            ),
          ),
        );
      },
      // The label itself never changes, so it is built once.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '+${formatWholeBaht(widget.yearlyAmount)} a year',
          style: textTheme.titleSmall?.copyWith(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
