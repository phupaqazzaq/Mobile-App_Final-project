import 'package:flutter_test/flutter_test.dart';
import 'package:nopoverty/models/expense.dart';
import 'package:nopoverty/models/recurring_payment.dart';
import 'package:nopoverty/utils/formatters.dart';

void main() {
  group('Expense', () {
    test('toMap() and fromMap() round-trip an expense', () {
      final expense = Expense(
        id: 7,
        title: 'Lunch',
        amount: 60.5,
        category: 'Food',
        date: DateTime(2026, 11, 5, 12, 30),
      );

      final map = expense.toMap();
      // The date and time are stored as an ISO 8601 string.
      expect(map['date'], '2026-11-05T12:30:00.000');

      final copy = Expense.fromMap(map);
      expect(copy.id, 7);
      expect(copy.title, 'Lunch');
      expect(copy.amount, 60.5);
      expect(copy.category, 'Food');
      expect(copy.date, DateTime(2026, 11, 5, 12, 30));
    });

    test('fromMap() accepts a whole-number amount stored as an int', () {
      final expense = Expense.fromMap({
        'id': 1,
        'title': 'Bus',
        'amount': 15,
        'category': 'Transport',
        'date': '2026-11-01T08:00:00.000',
      });
      expect(expense.amount, 15.0);
    });

    test('copyWith() keeps the id and changes only the given fields', () {
      final expense = Expense(
        id: 3,
        title: 'Bus',
        amount: 15,
        category: 'Transport',
        date: DateTime(2026, 11, 1),
      );

      final edited = expense.copyWith(title: 'Taxi', amount: 120);
      expect(edited.id, 3);
      expect(edited.title, 'Taxi');
      expect(edited.amount, 120);
      expect(edited.category, 'Transport');
      expect(edited.date, DateTime(2026, 11, 1));
    });
  });

  group('RecurringPayment', () {
    // A monthly item paid on the given day of the month.
    RecurringPayment monthly(int day) {
      return RecurringPayment(
        name: 'Phone bill',
        amount: 299,
        category: 'Bills',
        type: RecurringPayment.fixed,
        billingCycle: RecurringPayment.monthly,
        paymentDay: day,
      );
    }

    // A yearly item paid on 15 March.
    const yearly = RecurringPayment(
      name: 'Insurance',
      amount: 1200,
      category: 'Bills',
      type: RecurringPayment.fixed,
      billingCycle: RecurringPayment.yearly,
      paymentDay: 15,
      startMonth: 3,
    );

    test('toMap() and fromMap() round-trip a monthly item', () {
      const item = RecurringPayment(
        id: 4,
        name: 'Netflix',
        amount: 419,
        category: 'Entertainment',
        type: RecurringPayment.subscription,
        billingCycle: RecurringPayment.monthly,
        paymentDay: 20,
      );

      final map = item.toMap();
      expect(map['billing_cycle'], 'monthly');
      expect(map['payment_day'], 20);
      expect(map['start_month'], isNull);
      expect(map['is_active'], 1);

      final copy = RecurringPayment.fromMap(map);
      expect(copy.id, 4);
      expect(copy.name, 'Netflix');
      expect(copy.amount, 419);
      expect(copy.category, 'Entertainment');
      expect(copy.type, RecurringPayment.subscription);
      expect(copy.billingCycle, RecurringPayment.monthly);
      expect(copy.paymentDay, 20);
      expect(copy.startMonth, isNull);
      expect(copy.isActive, isTrue);
    });

    test('toMap() and fromMap() round-trip a yearly, inactive item', () {
      const item = RecurringPayment(
        id: 5,
        name: 'Insurance',
        amount: 1200,
        category: 'Bills',
        type: RecurringPayment.fixed,
        billingCycle: RecurringPayment.yearly,
        paymentDay: 15,
        startMonth: 3,
        isActive: false,
      );

      final map = item.toMap();
      expect(map['start_month'], 3);
      expect(map['is_active'], 0);

      final copy = RecurringPayment.fromMap(map);
      expect(copy.billingCycle, RecurringPayment.yearly);
      expect(copy.startMonth, 3);
      expect(copy.isActive, isFalse);
    });

    test('monthlyCost of a ฿1,200 yearly item is ฿100', () {
      expect(yearly.monthlyCost, 100);
      expect(yearly.yearlyCost, 1200);
    });

    test('a monthly item costs its amount per month, × 12 per year', () {
      expect(monthly(10).monthlyCost, 299);
      expect(monthly(10).yearlyCost, 3588);
    });

    test('nextPaymentDate for a day that has passed rolls to next month', () {
      final today = DateTime(2026, 11, 15);
      expect(monthly(10).nextPaymentDate(today), DateTime(2026, 12, 10));
    });

    test('nextPaymentDate stays in this month for today or a later day', () {
      final today = DateTime(2026, 11, 15);
      expect(monthly(15).nextPaymentDate(today), DateTime(2026, 11, 15));
      expect(monthly(20).nextPaymentDate(today), DateTime(2026, 11, 20));
    });

    test('nextPaymentDate rolls from December into January', () {
      final today = DateTime(2026, 12, 20);
      expect(monthly(10).nextPaymentDate(today), DateTime(2027, 1, 10));
    });

    test('nextPaymentDate of a yearly item uses its month', () {
      expect(
        yearly.nextPaymentDate(DateTime(2026, 2, 1)),
        DateTime(2026, 3, 15),
      );
      expect(
        yearly.nextPaymentDate(DateTime(2026, 3, 15)),
        DateTime(2026, 3, 15),
      );
      // This year's date has passed, so it rolls to next year.
      expect(
        yearly.nextPaymentDate(DateTime(2026, 11, 15)),
        DateTime(2027, 3, 15),
      );
    });

    test('daysUntilNextPayment counts the days from today', () {
      // The time of day must not matter.
      final today = DateTime(2026, 11, 15, 23, 59);
      expect(monthly(15).daysUntilNextPayment(today), 0);
      expect(monthly(20).daysUntilNextPayment(today), 5);
      expect(monthly(10).daysUntilNextPayment(today), 25);
    });

    test('totalMonthlyCost counts only active items', () {
      final items = [
        monthly(10),
        yearly,
        const RecurringPayment(
          name: 'Netflix',
          amount: 419,
          category: 'Entertainment',
          type: RecurringPayment.subscription,
          billingCycle: RecurringPayment.monthly,
          paymentDay: 20,
        ),
        const RecurringPayment(
          name: 'Old gym',
          amount: 1000,
          category: 'Other',
          type: RecurringPayment.subscription,
          billingCycle: RecurringPayment.monthly,
          paymentDay: 1,
          isActive: false,
        ),
      ];

      expect(RecurringPayment.totalMonthlyCost(items), 299 + 100 + 419);
      expect(
        RecurringPayment.totalMonthlyCost(
          items,
          type: RecurringPayment.subscription,
        ),
        419,
      );
      expect(RecurringPayment.totalMonthlyCost(items, category: 'Bills'), 399);
    });
  });

  group('formatters', () {
    test('format money, dates and times the way the app shows them', () {
      expect(formatBaht(1250), '฿1,250.00');
      expect(formatWholeBaht(5028), '฿5,028');
      expect(
        formatDateTime(DateTime(2026, 11, 5, 12, 30)),
        '05 Nov 2026, 12:30',
      );
      expect(formatDate(DateTime(2026, 11, 5)), '05 Nov 2026');
      expect(formatMonth(DateTime(2026, 11)), 'November 2026');
      expect(formatMonthName(11), 'November');
    });

    test('amountToText drops the .0 of whole numbers', () {
      expect(amountToText(60), '60');
      expect(amountToText(60.5), '60.5');
    });

    test('validateAmount accepts only numbers greater than 0', () {
      expect(validateAmount('60.5'), isNull);
      expect(validateAmount(' 15 '), isNull);
      expect(validateAmount(''), isNotNull);
      expect(validateAmount(null), isNotNull);
      expect(validateAmount('abc'), isNotNull);
      expect(validateAmount('NaN'), isNotNull);
      expect(validateAmount('Infinity'), isNotNull);
      expect(validateAmount('0'), isNotNull);
      expect(validateAmount('-5'), isNotNull);
    });
  });
}
