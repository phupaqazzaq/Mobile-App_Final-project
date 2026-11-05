import 'package:flutter_test/flutter_test.dart';
import 'package:nopoverty/models/insight.dart';
import 'package:nopoverty/models/recurring_payment.dart';
import 'package:nopoverty/services/insight_service.dart';
import 'package:nopoverty/utils/categories.dart';

/// Runs the service. Every input is empty unless a test sets it. The date is
/// the middle of a 30-day month, so 15 days are left.
List<Insight> generate({
  Map<String, double> thisMonth = const {},
  Map<String, double> lastMonth = const {},
  Map<String, double> budgets = const {},
  List<RecurringPayment> recurring = const [],
  DateTime? today,
}) {
  return const InsightService(tips: categoryTips).generate(
    thisMonth: thisMonth,
    lastMonth: lastMonth,
    budgets: budgets,
    recurring: recurring,
    today: today ?? DateTime(2026, 11, 15),
  );
}

/// The messages of the suggestions made by one rule. Each rule has its own icon.
List<String> messagesOf(List<Insight> insights, InsightIcon rule) {
  return [
    for (final insight in insights)
      if (insight.icon == rule) insight.message,
  ];
}

RecurringPayment fixedCost(double amount, {String category = 'Bills'}) {
  return RecurringPayment(
    name: 'Phone bill',
    amount: amount,
    category: category,
    type: RecurringPayment.fixed,
    billingCycle: RecurringPayment.monthly,
    paymentDay: 10,
  );
}

RecurringPayment subscription(
  double amount, {
  String category = 'Entertainment',
  String billingCycle = RecurringPayment.monthly,
  bool isActive = true,
}) {
  return RecurringPayment(
    name: 'Netflix',
    amount: amount,
    category: category,
    type: RecurringPayment.subscription,
    billingCycle: billingCycle,
    paymentDay: 20,
    startMonth: billingCycle == RecurringPayment.yearly ? 3 : null,
    isActive: isActive,
  );
}

void main() {
  test('every category has two tips', () {
    for (final category in categories) {
      expect(categoryTips[category.name], hasLength(2), reason: category.name);
    }
  });

  group('Rule 1: top category', () {
    test('names the biggest share of daily spending, with a tip', () {
      final insights = generate(thisMonth: {'Food': 840, 'Transport': 160});
      expect(messagesOf(insights, InsightIcon.topCategory), [
        'Food is 84% of your daily spending. Try bringing lunch from home.',
      ]);
    });

    test('gives the first tip in November and the second in December', () {
      final november = generate(
        thisMonth: {'Food': 100},
        today: DateTime(2026, 11, 15),
      );
      final december = generate(
        thisMonth: {'Food': 100},
        today: DateTime(2026, 12, 15),
      );
      expect(
        messagesOf(november, InsightIcon.topCategory).single,
        contains('Try bringing lunch from home.'),
      );
      expect(
        messagesOf(december, InsightIcon.topCategory).single,
        contains('Cut down on delivery fees by ordering less often.'),
      );
    });

    test('ignores recurring payments, like the pie chart', () {
      final insights = generate(
        thisMonth: {'Food': 100},
        recurring: [fixedCost(5000)],
      );
      expect(
        messagesOf(insights, InsightIcon.topCategory).single,
        startsWith('Food is 100%'),
      );
    });

    test('stays silent when there is no daily spending', () {
      final insights = generate(recurring: [fixedCost(5000)]);
      expect(messagesOf(insights, InsightIcon.topCategory), isEmpty);
    });
  });

  group('Rule 2: over budget', () {
    test('triggers when spent is more than the limit', () {
      final insights = generate(
        thisMonth: {'Shopping': 800},
        budgets: {'Shopping': 500},
      );
      expect(messagesOf(insights, InsightIcon.overBudget), [
        'You are ฿300 over your Shopping budget.',
      ]);
      expect(
        insights.firstWhere((i) => i.icon == InsightIcon.overBudget).severity,
        InsightSeverity.alert,
      );
    });

    test('counts recurring payments as spent', () {
      final insights = generate(
        thisMonth: {'Entertainment': 100},
        budgets: {'Entertainment': 500},
        recurring: [subscription(419)],
      );
      expect(messagesOf(insights, InsightIcon.overBudget), [
        'You are ฿19 over your Entertainment budget.',
      ]);
    });

    test('stays silent at exactly the limit', () {
      final insights = generate(
        thisMonth: {'Shopping': 500},
        budgets: {'Shopping': 500},
      );
      expect(messagesOf(insights, InsightIcon.overBudget), isEmpty);
    });

    test('does not count inactive recurring payments', () {
      final insights = generate(
        thisMonth: {'Entertainment': 100},
        budgets: {'Entertainment': 500},
        recurring: [subscription(419, isActive: false)],
      );
      expect(messagesOf(insights, InsightIcon.overBudget), isEmpty);
    });
  });

  group('Rule 3: near budget', () {
    test('triggers at exactly 80% of the limit', () {
      final insights = generate(
        thisMonth: {'Food': 1600},
        budgets: {'Food': 2000},
      );
      expect(messagesOf(insights, InsightIcon.nearBudget), [
        '80% of your Food budget is used with 15 days left.',
      ]);
      expect(
        insights.firstWhere((i) => i.icon == InsightIcon.nearBudget).severity,
        InsightSeverity.warning,
      );
    });

    test('says "1 day" on the second-to-last day of the month', () {
      final insights = generate(
        thisMonth: {'Food': 1600},
        budgets: {'Food': 2000},
        today: DateTime(2026, 11, 29),
      );
      expect(
        messagesOf(insights, InsightIcon.nearBudget).single,
        endsWith('with 1 day left.'),
      );
    });

    test('stays silent below 80%', () {
      final insights = generate(
        thisMonth: {'Food': 1599},
        budgets: {'Food': 2000},
      );
      expect(messagesOf(insights, InsightIcon.nearBudget), isEmpty);
    });

    test('stays silent above 100%, because rule 2 covers that', () {
      final insights = generate(
        thisMonth: {'Food': 2100},
        budgets: {'Food': 2000},
      );
      expect(messagesOf(insights, InsightIcon.nearBudget), isEmpty);
    });
  });

  group('Rule 4: projected overspend', () {
    test('triggers when the pace would pass the limit', () {
      final insights = generate(
        thisMonth: {'Food': 1600},
        budgets: {'Food': 2000},
      );
      expect(messagesOf(insights, InsightIcon.projectedOverspend), [
        "At this pace you'll spend ฿3,200 on food this month, ฿1,200 over "
            'budget.',
      ]);
      expect(
        insights
            .firstWhere((i) => i.icon == InsightIcon.projectedOverspend)
            .severity,
        InsightSeverity.warning,
      );
    });

    test('only starts after day 5', () {
      final dayFive = generate(
        thisMonth: {'Food': 500},
        budgets: {'Food': 2000},
        today: DateTime(2026, 11, 5),
      );
      final daySix = generate(
        thisMonth: {'Food': 500},
        budgets: {'Food': 2000},
        today: DateTime(2026, 11, 6),
      );
      expect(messagesOf(dayFive, InsightIcon.projectedOverspend), isEmpty);
      expect(messagesOf(daySix, InsightIcon.projectedOverspend), hasLength(1));
    });

    test('stays silent when the pace ends exactly at the limit', () {
      final insights = generate(
        thisMonth: {'Transport': 300},
        budgets: {'Transport': 600},
      );
      expect(messagesOf(insights, InsightIcon.projectedOverspend), isEmpty);
    });

    test('adds recurring payments without speeding them up', () {
      // ฿300 in 15 days is ฿600 for the month, plus ฿419 for the subscription.
      final insights = generate(
        thisMonth: {'Entertainment': 300},
        budgets: {'Entertainment': 1000},
        recurring: [subscription(419)],
      );
      expect(messagesOf(insights, InsightIcon.projectedOverspend), [
        "At this pace you'll spend ฿1,019 on entertainment this month, ฿19 "
            'over budget.',
      ]);
    });

    test('stays silent for a category with no daily spending', () {
      final insights = generate(
        budgets: {'Entertainment': 300},
        recurring: [subscription(419)],
      );
      expect(messagesOf(insights, InsightIcon.projectedOverspend), isEmpty);
    });
  });

  group('Rule 5: rising category', () {
    test('triggers when a category is up 30% and at least ฿300', () {
      final insights = generate(
        thisMonth: {'Transport': 1450},
        lastMonth: {'Transport': 1000},
      );
      expect(messagesOf(insights, InsightIcon.risingCategory), [
        'Transport is up 45% from last month.',
      ]);
    });

    test('triggers at exactly 30% and exactly ฿300', () {
      final insights = generate(
        thisMonth: {'Transport': 1300},
        lastMonth: {'Transport': 1000},
      );
      expect(messagesOf(insights, InsightIcon.risingCategory), hasLength(1));
    });

    test('stays silent below 30%, even with a big difference', () {
      final insights = generate(
        thisMonth: {'Transport': 2400},
        lastMonth: {'Transport': 2000},
      );
      expect(messagesOf(insights, InsightIcon.risingCategory), isEmpty);
    });

    test('stays silent below ฿300, even with a big percentage', () {
      final insights = generate(
        thisMonth: {'Transport': 200},
        lastMonth: {'Transport': 100},
      );
      expect(messagesOf(insights, InsightIcon.risingCategory), isEmpty);
    });

    test('stays silent when nothing was spent last month', () {
      final insights = generate(thisMonth: {'Transport': 1000});
      expect(messagesOf(insights, InsightIcon.risingCategory), isEmpty);
    });
  });

  group('Rule 6: subscription cost', () {
    test('adds up the active subscriptions per year', () {
      final insights = generate(
        recurring: [subscription(299), subscription(69), subscription(51)],
      );
      expect(messagesOf(insights, InsightIcon.subscription), [
        'Your 3 subscriptions cost ฿5,028 a year. Cancel any you no longer '
            'use.',
      ]);
    });

    test('uses the right words for one subscription', () {
      final insights = generate(recurring: [subscription(419)]);
      expect(messagesOf(insights, InsightIcon.subscription), [
        'Your 1 subscription costs ฿5,028 a year. Cancel it if you no longer '
            'use it.',
      ]);
    });

    test('counts a yearly subscription at its yearly amount', () {
      final insights = generate(
        recurring: [
          subscription(1200, billingCycle: RecurringPayment.yearly),
          subscription(100),
        ],
      );
      expect(
        messagesOf(insights, InsightIcon.subscription).single,
        contains('฿2,400 a year'),
      );
    });

    test('stays silent with no active subscriptions', () {
      final insights = generate(
        recurring: [subscription(419, isActive: false), fixedCost(299)],
      );
      expect(messagesOf(insights, InsightIcon.subscription), isEmpty);
    });
  });

  group('Rule 7: fixed cost share', () {
    test('triggers when fixed costs are more than half the total', () {
      final insights = generate(
        thisMonth: {'Food': 1900},
        recurring: [fixedCost(3100)],
      );
      expect(messagesOf(insights, InsightIcon.fixedCost), [
        'Fixed costs are 62% of your spending. Look for a cheaper phone plan '
            'or shared housing.',
      ]);
    });

    test('stays silent at exactly half the total', () {
      final insights = generate(
        thisMonth: {'Food': 1000},
        recurring: [fixedCost(1000)],
      );
      expect(messagesOf(insights, InsightIcon.fixedCost), isEmpty);
    });

    test('counts subscriptions in the total', () {
      final insights = generate(
        recurring: [fixedCost(1000), subscription(1000)],
      );
      expect(messagesOf(insights, InsightIcon.fixedCost), isEmpty);
    });

    test('stays silent with no spending at all', () {
      expect(messagesOf(generate(), InsightIcon.fixedCost), isEmpty);
    });
  });

  group('Rule 8: no budgets', () {
    test('triggers when no budgets are set', () {
      expect(messagesOf(generate(), InsightIcon.noBudget), [
        'Set a budget for your biggest category to start saving.',
      ]);
    });

    test('stays silent once a budget is set', () {
      final insights = generate(budgets: {'Food': 2000});
      expect(messagesOf(insights, InsightIcon.noBudget), isEmpty);
    });
  });

  test('alerts come before warnings, and warnings before info', () {
    final insights = generate(
      thisMonth: {'Food': 1600, 'Shopping': 800},
      budgets: {'Food': 2000, 'Shopping': 500},
      recurring: [subscription(419)],
    );

    final severities = insights.map((insight) => insight.severity).toList();
    expect(severities, [
      InsightSeverity.alert, // over the Shopping budget
      InsightSeverity.warning, // near the Food budget
      InsightSeverity.warning, // projected overspend on Food
      InsightSeverity.warning, // projected overspend on Shopping
      InsightSeverity.info, // top category
      InsightSeverity.info, // subscription cost
    ]);
  });

  test("the proposal's scenario gives the proposal's wording", () {
    final insights = generate(
      today: DateTime(2026, 11, 15), // a 30-day month
      thisMonth: {'Food': 1600, 'Transport': 300},
      budgets: {'Food': 2000, 'Transport': 600},
      recurring: [fixedCost(299), subscription(419)],
    );
    final messages = insights.map((insight) => insight.message).toList();

    expect(
      messages,
      contains(
        'Food is 84% of your daily spending. Try bringing lunch from home.',
      ),
    );
    expect(
      messages,
      contains('80% of your Food budget is used with 15 days left.'),
    );

    final projected = messagesOf(insights, InsightIcon.projectedOverspend);
    expect(projected, hasLength(1));
    expect(projected.single, contains('฿3,200'));
    expect(projected.single, contains('฿1,200 over budget'));

    expect(
      messagesOf(insights, InsightIcon.subscription).single,
      contains('฿5,028 a year'),
    );

    // Transport is at 50% and on pace for exactly its limit, so no warnings.
    final warnings = insights.where(
      (insight) => insight.severity == InsightSeverity.warning,
    );
    expect(warnings, hasLength(2));
    for (final warning in warnings) {
      expect(warning.message, isNot(contains('Transport')));
      expect(warning.message, isNot(contains('transport')));
    }

    // Nothing is over budget, and fixed costs are only 11% of the total.
    expect(messagesOf(insights, InsightIcon.overBudget), isEmpty);
    expect(messagesOf(insights, InsightIcon.fixedCost), isEmpty);
  });
}
