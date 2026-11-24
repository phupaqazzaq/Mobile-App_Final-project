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

### Animations

- Totals count up or down to their new values on Home and Recurring.
- The add-expense form opens as a circle growing out of the **+** button, and a new expense slides into the list.
- Budget bars fill one after another, change color as they fill, and give one small shake when over budget.
- Switching a subscription off shows what it saves per year (e.g. +฿5,028 a year) floating up with a few coins.
- The pie chart sweeps in, a tapped slice grows and its legend row lights up, and the suggestion cards slide up one by one.
- With **Remove animations** turned on in Android's accessibility settings, everything appears at once.

All data is stored on the phone in a local SQLite database, so the app works offline with no account or login. All forms check their input and show errors under the fields.

## Tech Stack

- [Flutter](https://flutter.dev) 3.47 (Dart 3.13), with Material 3
- [sqflite](https://pub.dev/packages/sqflite): local SQLite database
- [path](https://pub.dev/packages/path): builds the database file path
- [intl](https://pub.dev/packages/intl): formats Thai Baht amounts and dates
- [fl_chart](https://pub.dev/packages/fl_chart): draws the pie chart
- [flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html): unit and widget tests

There is no backend server or API: everything runs on the phone.

## Installation

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47 or newer (it includes Dart 3.13).
- [Android Studio](https://developer.android.com/studio) with the Android SDK. Accept the Android licenses with `flutter doctor --android-licenses`.
- An Android emulator (Android Studio: **Virtual Device Manager**) or an Android phone with **USB debugging** turned on.

Run `flutter doctor` to check that Flutter and the Android toolchain are ready.

### Run the app

1. Download the code and open its folder:

   ```bash
   git clone https://github.com/phupaqazzaq/Mobile-App_Final-project.git
   cd Mobile-App_Final-project
   ```

2. Get the packages:

   ```bash
   flutter pub get
   ```

3. Start the emulator or connect the phone, and check that Flutter sees it:

   ```bash
   flutter devices
   ```

4. Run the app:

   ```bash
   flutter run
   ```

### Install it as an APK

```bash
flutter build apk --release
```

The file is `build/app/outputs/flutter-apk/app-release.apk`. Copy it to an Android phone and open it to install, or install it on a connected phone with `adb install build/app/outputs/flutter-apk/app-release.apk`.

### Run the tests

```bash
flutter test
```

## Database

The app creates the SQLite file `nopoverty.db` the first time it starts, with three tables: `expenses`, `budgets` and `recurring_payments`.

- [`sql/schema.sql`](sql/schema.sql) has the same `CREATE TABLE` statements as the app, with notes on each column.
- [`sql/sample_data.sql`](sql/sample_data.sql) has the example data we used for testing: ฿1,600 of food and ฿300 of transport, budgets of ฿2,000 for food and ฿600 for transport, a ฿299 phone bill and a ฿419 Netflix subscription.

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
│   ├── formatters.dart            # Baht and date formats, amount checks
│   └── motion.dart                # Shared animation timings, Remove animations check
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
    ├── rolling_amount.dart        # An amount that counts to its new value
    ├── expense_tile.dart          # One expense in the list
    ├── budget_tile.dart           # One category's budget, with the animated bar
    ├── recurring_tile.dart        # One fixed cost or subscription
    ├── savings_float.dart         # The "+฿X a year" label with coins
    └── insight_card.dart          # One suggestion
sql/
├── schema.sql                     # The three tables
└── sample_data.sql                # Example data for testing
test/
├── models_test.dart               # Models and formatters
├── insight_service_test.dart      # Every suggestion rule
└── summary_card_test.dart         # The rolling total
```
