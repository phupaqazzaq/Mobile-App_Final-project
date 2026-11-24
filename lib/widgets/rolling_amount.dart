import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../utils/motion.dart';

/// An amount of money that counts up or down to its new value whenever
/// [amount] changes, e.g. from ฿1,900.00 to ฿2,319.00. The first time it is
/// shown, it counts up from ฿0.
///
/// TweenAnimationBuilder drives it: when [amount] changes, it animates from
/// the number on screen to the new one in 600 ms and rebuilds the Text every
/// frame, formatted with [format].
class RollingAmount extends StatelessWidget {
  const RollingAmount({
    super.key,
    required this.amount,
    this.format = formatBaht,
    this.prefix = '',
    this.style,
  });

  /// The amount to show, in Thai Baht.
  final double amount;

  /// Turns a number into text: formatBaht (฿1,250.00) or formatWholeBaht
  /// (฿1,250).
  final String Function(double amount) format;

  /// Text in front of the amount, e.g. "Daily spending ".
  final String prefix;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // After the first build only `end` matters: a new end makes the
      // builder animate from the value it is showing right now.
      tween: Tween(begin: 0, end: amount),
      duration: Motion.duration(context, Motion.rollNumber),
      curve: Motion.curve,
      builder: (context, value, child) {
        return Text('$prefix${format(value)}', style: style);
      },
    );
  }
}
