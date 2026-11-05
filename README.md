# NoPoverty

A smart personal expense tracker for Android: record your spending, set a budget for each category, track fixed costs and subscriptions, and get simple suggestions on how to spend less.

**Course:** ITCS259 Mobile Application Development

**Scope:** Option 1, Mobile App with Local Database (SQLite)

## Team Members

| Name | Student ID |
| --- | --- |
| Natdanai Chuwongapichat | 6788019 |
| Duarn Kaeokertkhen | 6788034 |

## Features

### Home

- **Add expense:** a form with amount, title and category. The date and time fill in automatically, and you can change them.
- **View expenses:** a scrollable list, newest first.
- **Edit expense:** tap an item to open the same form pre-filled.
- **Delete expense:** swipe an item to the left, with an **Undo** button in the SnackBar.
- **Monthly summary:** the total this month in Thai Baht (e.g. ฿1,250.00), split into daily spending and fixed costs and subscriptions.
- **Top suggestion:** the most important suggestion, with a link to see them all.
- **Filter by category:** chips for All, Food, Transport, Shopping, Bills, Entertainment and Other.

### Budgets

- One row per category with its spending, its monthly limit and a progress bar.
- The bar is green below 80%, orange from 80% to 100%, and red above 100%.
- Tap a row to set, change or remove the limit.

### Recurring

- Separate lists for fixed costs and subscriptions, with monthly or yearly billing.
- Each item shows its next payment date, and subscriptions also show their yearly cost.
- The header shows the total per month for each type and the total per year for subscriptions.
- Items can be switched off without deleting them, and swiping to delete has **Undo**.

### Insights

- A pie chart of this month's daily spending, with a legend of names, amounts and percentages.
- Suggestion cards from eight simple rules written in Dart: top category, over budget, near budget, projected overspend, rising category, subscription cost, fixed cost share and no budgets. No AI or internet is used.

All data is stored on the phone in a local SQLite database, so the app works offline with no account or login. All forms check their input and show errors under the fields.

## Tech Stack

- [Flutter](https://flutter.dev) (Dart)
- [sqflite](https://pub.dev/packages/sqflite): local SQLite database
- [path](https://pub.dev/packages/path): builds the database file path
- [intl](https://pub.dev/packages/intl): formats Thai Baht amounts and dates
- [fl_chart](https://pub.dev/packages/fl_chart): draws the pie chart

## How to Run

1. Start an Android emulator or connect an Android phone (the app targets Android only).
2. In the project folder, run:

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                      # App entry point and Material 3 theme
├── models/
│   ├── expense.dart               # Expense: toMap(), fromMap(), copyWith()
│   ├── recurring_payment.dart     # Monthly and yearly cost, next payment date
│   └── insight.dart               # One suggestion and its severity
├── database/database_helper.dart  # Singleton SQLite helper
├── services/insight_service.dart  # The suggestion rules, in plain Dart
├── utils/
│   ├── categories.dart            # Category names, icons, colors and tips
│   └── formatters.dart            # Baht and date formats, amount checks
├── screens/
│   ├── main_shell.dart            # NavigationBar with the four tabs
│   ├── home_screen.dart           # Summary, top suggestion, filters, expenses
│   ├── expense_form_screen.dart   # Add / edit expense
│   ├── budgets_screen.dart        # Category limits with progress bars
│   ├── recurring_screen.dart      # Fixed costs and subscriptions
│   ├── recurring_form_screen.dart # Add / edit recurring payment
│   └── insights_screen.dart       # Pie chart and suggestion cards
└── widgets/
    ├── summary_card.dart          # Monthly summary card
    ├── expense_tile.dart          # One expense in the list
    ├── budget_tile.dart           # One category's budget
    ├── recurring_tile.dart        # One fixed cost or subscription
    └── insight_card.dart          # One suggestion
```
