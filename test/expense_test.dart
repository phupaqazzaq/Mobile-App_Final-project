import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/expense.dart';
import 'package:spendwise/utils/categories.dart';

void main() {
  test('toMap() and fromMap() round-trip an expense', () {
    final expense = Expense(
      id: 7,
      title: 'Lunch',
      amount: 60.5,
      category: 'Food',
      date: DateTime(2026, 11, 5),
    );

    final map = expense.toMap();
    // The date is stored as an ISO 8601 string.
    expect(map['date'], '2026-11-05T00:00:00.000');

    final copy = Expense.fromMap(map);
    expect(copy.id, 7);
    expect(copy.title, 'Lunch');
    expect(copy.amount, 60.5);
    expect(copy.category, 'Food');
    expect(copy.date, DateTime(2026, 11, 5));
  });

  test('fromMap() accepts a whole-number amount stored as an int', () {
    final expense = Expense.fromMap({
      'id': 1,
      'title': 'Bus',
      'amount': 15,
      'category': 'Transport',
      'date': '2026-11-01T00:00:00.000',
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

  test('formatBaht() and formatDate() use the app formats', () {
    expect(formatBaht(1250), '฿1,250.00');
    expect(formatDate(DateTime(2026, 11, 5)), '05 Nov 2026');
  });
}
