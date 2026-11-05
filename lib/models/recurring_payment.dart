/// One fixed cost or subscription, i.e. one row of the `recurring_payments`
/// table. These are not copied into the expenses table: their monthly cost is
/// added to the totals whenever the totals are calculated.
class RecurringPayment {
  const RecurringPayment({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.type,
    required this.billingCycle,
    required this.paymentDay,
    this.startMonth,
    this.isActive = true,
  });

  /// Builds a RecurringPayment from a database row (the opposite of [toMap]).
  factory RecurringPayment.fromMap(Map<String, dynamic> map) {
    return RecurringPayment(
      id: map['id'] as int?,
      name: map['name'] as String,
      // SQLite may give back an int for whole numbers, so convert to double.
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: map['type'] as String,
      billingCycle: map['billing_cycle'] as String,
      paymentDay: map['payment_day'] as int,
      startMonth: map['start_month'] as int?,
      // SQLite has no true/false, so active is stored as 1 and inactive as 0.
      isActive: map['is_active'] == 1,
    );
  }

  // The values of the `type` column.
  static const String fixed = 'fixed';
  static const String subscription = 'subscription';

  // The values of the `billing_cycle` column.
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  /// Row id. It is null for a new item until SQLite gives it one.
  final int? id;

  /// Short description, e.g. "Phone bill" or "Netflix".
  final String name;

  /// What one payment costs in Thai Baht. Always greater than 0.
  final double amount;

  /// One of the category names in lib/utils/categories.dart, e.g. "Bills".
  final String category;

  /// Either [fixed] or [subscription].
  final String type;

  /// Either [monthly] or [yearly].
  final String billingCycle;

  /// The day of the month it is paid, from 1 to 28.
  final int paymentDay;

  /// The month it is paid, from 1 to 12. Only used for yearly items.
  final int? startMonth;

  /// Inactive items stay in the list but don't count towards any total.
  final bool isActive;

  /// Converts this item to a Map whose keys are the table's column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'type': type,
      'billing_cycle': billingCycle,
      'payment_day': paymentDay,
      'start_month': startMonth,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// What this item costs per month: the amount, or the amount ÷ 12 if it is
  /// paid once a year.
  double get monthlyCost => billingCycle == yearly ? amount / 12 : amount;

  /// What this item costs per year: the amount × 12, or the amount if it is
  /// paid once a year.
  double get yearlyCost => billingCycle == yearly ? amount : amount * 12;

  /// The next day this item has to be paid, counting from [today].
  DateTime nextPaymentDate(DateTime today) {
    if (billingCycle == yearly) {
      final month = startMonth ?? today.month;
      final thisYear = DateTime(today.year, month, paymentDay);
      final startOfToday = DateTime(today.year, today.month, today.day);
      return thisYear.isBefore(startOfToday)
          ? DateTime(today.year + 1, month, paymentDay)
          : thisYear;
    }

    if (paymentDay >= today.day) {
      return DateTime(today.year, today.month, paymentDay);
    }
    // Month 13 is fine: DateTime turns it into January of the next year.
    return DateTime(today.year, today.month + 1, paymentDay);
  }

  /// How many days from [today] until [nextPaymentDate]. 0 means today.
  int daysUntilNextPayment(DateTime today) {
    final next = nextPaymentDate(today);
    // Compare in UTC, where every day is exactly 24 hours long.
    return DateTime.utc(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }

  /// Adds up the monthly cost of the active items in [items]. Pass a [type]
  /// or a [category] to count only those items.
  static double totalMonthlyCost(
    Iterable<RecurringPayment> items, {
    String? type,
    String? category,
  }) {
    var total = 0.0;
    for (final item in items) {
      if (!item.isActive) continue;
      if (type != null && item.type != type) continue;
      if (category != null && item.category != category) continue;
      total += item.monthlyCost;
    }
    return total;
  }
}
