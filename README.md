# SpendWise

A personal expense tracker for Android: record your spending, sort it into categories, and see where your money goes each month.

**Course:** ITCS259 Mobile Application Development

**Scope:** Option 1, Mobile App with Local Database (SQLite)

## Team Members

| Name | Student ID |
| --- | --- |
| Duarn Kaeokertkhen | 6788034 |
| Natdanai Chuwongapichat | 6788019 |
|  |  |

## Features

1. **Add expense:** a form with amount, title, category and date, saved to SQLite.
2. **View expenses:** a scrollable list on the home screen, newest first.
3. **Edit expense:** tap an item to open the same form pre-filled; saving updates it.
4. **Delete expense:** swipe an item to the left to delete it, with an **Undo** button in the SnackBar.
5. **Monthly total:** a summary card shows the total spent this month in Thai Baht (e.g. ฿1,250.00).
6. **Filter by category:** chips for All, Food, Transport, Shopping, Bills and Other.
7. **Spending chart:** a pie chart of this month's spending by category, with a legend of names and amounts.
8. **Form validation:** the title can't be empty and the amount must be a number greater than 0.
9. **Empty state:** a friendly message when there are no expenses yet.

All data is stored on the phone in a local SQLite database, so the app works offline with no account or login.

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
├── main.dart                     # App entry point and Material 3 theme
├── models/expense.dart           # Expense class: toMap(), fromMap(), copyWith()
├── database/database_helper.dart # Singleton SQLite helper (CRUD and totals)
├── utils/categories.dart         # Category icons and colors, money and date formats
├── screens/
│   ├── home_screen.dart          # Summary card, filter chips, expense list, + button
│   ├── expense_form_screen.dart  # Add / edit form
│   └── chart_screen.dart         # Pie chart and legend
└── widgets/
    ├── summary_card.dart         # Monthly total card
    └── expense_tile.dart         # One expense in the list
```
