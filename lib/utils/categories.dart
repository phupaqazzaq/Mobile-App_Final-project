import 'package:flutter/material.dart';

/// One expense category: the name saved in the database, plus the icon and
/// color used for it in the lists and in the pie chart.
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
  ExpenseCategory('Entertainment', Icons.sports_esports, Colors.teal),
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

/// Two spending tips per category, used by the "top category" suggestion.
/// The suggestion picks one by month, so it changes from month to month.
const Map<String, List<String>> categoryTips = {
  'Food': [
    'Try bringing lunch from home.',
    'Cut down on delivery fees by ordering less often.',
  ],
  'Transport': [
    'Use a monthly BTS/MRT pass or share rides.',
    'Walk or cycle for short trips.',
  ],
  'Shopping': [
    'Wait 24 hours before buying anything non-essential.',
    'Make a shopping list and stick to it.',
  ],
  'Bills': [
    'Turn off the air-conditioner when you go out.',
    'Check if a cheaper phone or internet plan fits your usage.',
  ],
  'Entertainment': [
    'Look for free events or student discounts.',
    'Set a weekly limit for games and outings.',
  ],
  'Other': [
    'Review these expenses and give them a clearer category.',
    'Set a small monthly limit for things you can\'t categorize.',
  ],
};
