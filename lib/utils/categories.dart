import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One expense category: the name saved in the database, plus the icon and
/// color used for it in the list and in the pie chart.
class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

/// The fixed list of categories. This is the only place they are defined:
/// to change a category's icon or color, edit it here.
const List<ExpenseCategory> categories = [
  ExpenseCategory('Food', Icons.restaurant, Colors.orange),
  ExpenseCategory('Transport', Icons.directions_bus, Colors.blue),
  ExpenseCategory('Shopping', Icons.shopping_bag, Colors.purple),
  ExpenseCategory('Bills', Icons.receipt_long, Colors.red),
  ExpenseCategory('Other', Icons.category, Colors.blueGrey),
];

/// Finds a category by its name, e.g. categoryFor('Food').
/// Unknown names fall back to "Other" (the last item in the list).
ExpenseCategory categoryFor(String name) {
  return categories.firstWhere(
    (category) => category.name == name,
    orElse: () => categories.last,
  );
}

// Formatters are created once and reused.
final NumberFormat _bahtFormat = NumberFormat.currency(
  locale: 'th_TH',
  symbol: '฿',
);
final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'en_US');
final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'en_US');

/// Formats an amount as Thai Baht, e.g. 1250 becomes ฿1,250.00
String formatBaht(double amount) => _bahtFormat.format(amount);

/// Formats a date as dd MMM yyyy, e.g. 05 Nov 2026.
String formatDate(DateTime date) => _dateFormat.format(date);

/// Formats a month as its name and year, e.g. November 2026.
String formatMonth(DateTime month) => _monthFormat.format(month);
