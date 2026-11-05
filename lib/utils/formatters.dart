import 'package:intl/intl.dart';

// Formatters are created once and reused. This file uses no Flutter, so the
// insight service can use it too.
final NumberFormat _bahtFormat = NumberFormat.currency(
  locale: 'th_TH',
  symbol: '฿',
);
final NumberFormat _wholeBahtFormat = NumberFormat.currency(
  locale: 'th_TH',
  symbol: '฿',
  decimalDigits: 0,
);
final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'en_US');
final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'en_US');
final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'en_US');
final DateFormat _monthNameFormat = DateFormat('MMMM', 'en_US');

/// Formats an amount as Thai Baht, e.g. 1250 becomes ฿1,250.00
String formatBaht(double amount) => _bahtFormat.format(amount);

/// Formats an amount as whole Thai Baht, e.g. 5028 becomes ฿5,028
String formatWholeBaht(double amount) => _wholeBahtFormat.format(amount);

/// Formats a date and time, e.g. 05 Nov 2026, 12:30
String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

/// Formats a date, e.g. 05 Nov 2026.
String formatDate(DateTime date) => _dateFormat.format(date);

/// Formats a month as its name and year, e.g. November 2026.
String formatMonth(DateTime month) => _monthFormat.format(month);

/// Returns the name of a month from 1 to 12, e.g. 11 becomes November.
String formatMonthName(int month) {
  return _monthNameFormat.format(DateTime(2000, month));
}

/// Writes an amount for a form field: 60 instead of 60.0 for whole numbers.
String amountToText(double amount) {
  if (amount == amount.truncateToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toString();
}

/// Checks a form's amount field: it must be a valid number greater than 0.
/// Returns the error text to show under the field, or null if it is fine.
String? validateAmount(String? value) {
  final amount = double.tryParse(value?.trim() ?? '');
  // isFinite also rejects text like "NaN" or "Infinity".
  if (amount == null || !amount.isFinite) {
    return 'Please enter a valid number';
  }
  if (amount <= 0) {
    return 'Amount must be greater than 0';
  }
  return null;
}
