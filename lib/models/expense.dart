/// One expense, i.e. one row of the `expenses` table in SQLite.
class Expense {
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  /// Builds an Expense from a database row (the opposite of [toMap]).
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      // SQLite may give back an int for whole numbers, so convert to double.
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  /// Row id. It is null for a new expense until SQLite gives it one.
  final int? id;

  /// Short description, e.g. "Lunch".
  final String title;

  /// Amount in Thai Baht. Always greater than 0.
  final double amount;

  /// One of the category names in lib/utils/categories.dart, e.g. "Food".
  final String category;

  /// The date and time of the expense.
  final DateTime date;

  /// Converts this expense to a Map whose keys are the table's column names,
  /// so sqflite can save it. The date is saved as an ISO 8601 string,
  /// e.g. 2026-11-05T12:30:00.000.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  /// Returns a copy of this expense with only the given fields changed.
  /// Used when editing, so the edited expense keeps the same id.
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}
