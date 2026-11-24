import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nopoverty/widgets/rolling_amount.dart';
import 'package:nopoverty/widgets/summary_card.dart';

void main() {
  // Puts a widget on a screen, with animations on or off.
  Widget app(Widget child, {bool animationsOff = false}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: animationsOff),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('SummaryCard rolls up to the exact total', (tester) async {
    await tester.pumpWidget(
      app(
        SummaryCard(
          dailySpending: 1900,
          recurringCost: 718,
          month: DateTime(2026, 11),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('฿2,618.00'), findsOneWidget);
    expect(find.text('Daily spending ฿1,900.00'), findsOneWidget);
    expect(find.text('Fixed & subscriptions ฿718.00'), findsOneWidget);
  });

  testWidgets('RollingAmount shows in-between numbers, then the new amount', (
    tester,
  ) async {
    await tester.pumpWidget(app(const RollingAmount(amount: 100)));
    await tester.pumpAndSettle();
    expect(find.text('฿100.00'), findsOneWidget);

    await tester.pumpWidget(app(const RollingAmount(amount: 200)));
    await tester.pump(const Duration(milliseconds: 100));
    // Part way through, neither the old nor the new amount is shown.
    expect(find.text('฿100.00'), findsNothing);
    expect(find.text('฿200.00'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('฿200.00'), findsOneWidget);
  });

  testWidgets('with animations turned off, the total shows at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        SummaryCard(
          dailySpending: 1900,
          recurringCost: 718,
          month: DateTime(2026, 11),
        ),
        animationsOff: true,
      ),
    );

    // No time has passed, yet the final total is already on screen.
    expect(find.text('฿2,618.00'), findsOneWidget);
  });
}
