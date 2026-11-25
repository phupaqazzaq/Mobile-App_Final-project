import 'package:flutter/widgets.dart';

/// The timings and curve shared by every animation in the app, so they all
/// feel the same. Each animation lasts between 250 and 800 ms, except the
/// savings label on the Recurring tab, which the design gives 900 ms.
class Motion {
  // Only static members: the class is never created.
  Motion._();

  /// The curve every animation uses.
  static const Curve curve = Curves.easeOutCubic;

  /// A money amount counting up or down to its new value.
  static const Duration rollNumber = Duration(milliseconds: 600);

  /// The add-expense form growing out of the + button.
  static const Duration reveal = Duration(milliseconds: 450);

  /// A newly added expense sliding into the list.
  static const Duration newItem = Duration(milliseconds: 300);

  /// The top suggestion on Home fading and sliding into place.
  static const Duration banner = Duration(milliseconds: 400);

  /// A budget bar filling up.
  static const Duration barFill = Duration(milliseconds: 600);

  /// How much later each budget row starts filling than the row above it.
  static const Duration barStagger = Duration(milliseconds: 80);

  /// The small shake of a bar that is over budget.
  static const Duration shake = Duration(milliseconds: 300);

  /// The "+฿5,028 a year" label floating up when a subscription is switched
  /// off.
  static const Duration savingsFloat = Duration(milliseconds: 900);

  /// The pie chart sweeping in, and a tapped slice growing.
  static const Duration pieSweep = Duration(milliseconds: 800);

  /// A suggestion card sliding up on the Insights tab.
  static const Duration card = Duration(milliseconds: 400);

  /// How much later each suggestion card starts than the one above it.
  static const Duration cardStagger = Duration(milliseconds: 100);

  /// A legend row lighting up when its slice is tapped.
  static const Duration highlight = Duration(milliseconds: 250);

  /// The white pill of the navigation bar moving to the tab that was tapped.
  static const Duration tabSwitch = Duration(milliseconds: 300);

  /// True when the user has turned animations off, for example with
  /// Android's Settings > Accessibility > Remove animations.
  static bool isOff(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Returns [duration], or Duration.zero when animations are turned off, so
  /// everything appears at once. Every animation gets its duration from here.
  static Duration duration(BuildContext context, Duration duration) {
    return isOff(context) ? Duration.zero : duration;
  }

  /// TweenAnimationBuilder has no start delay. To make the items of a list
  /// animate one after another, item [index] gets a longer duration
  /// (index × [step] + [duration]) together with this curve, which waits at
  /// the start for the first index × [step] and then runs [curve].
  static Curve staggered(int index, Duration step, Duration duration) {
    final delay = step * index;
    final total = delay + duration;
    return Interval(
      delay.inMicroseconds / total.inMicroseconds,
      1,
      curve: curve,
    );
  }
}
