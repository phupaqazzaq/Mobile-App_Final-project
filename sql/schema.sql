-- NoPoverty database schema (SQLite).
--
-- The app creates these three tables itself the first time it opens the
-- database file nopoverty.db (DatabaseHelper._onCreate in
-- lib/database/database_helper.dart). This file is a copy of those
-- statements, so the schema can be read and tested without the app.

-- One row per expense. The date holds the date and time as ISO 8601 text,
-- e.g. 2026-11-05T12:30:00.000.
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  date TEXT NOT NULL
);

-- One monthly limit per category. A category without a row has no budget.
CREATE TABLE budgets (
  category TEXT PRIMARY KEY,
  monthly_limit REAL NOT NULL
);

-- Fixed costs and subscriptions. They are not copied into expenses: their
-- monthly cost is added whenever the app calculates a total.
--   type:          'fixed' or 'subscription'
--   billing_cycle: 'monthly' or 'yearly'
--   payment_day:   1 to 28
--   start_month:   1 to 12 for yearly items (the month they are paid), else NULL
--   is_active:     1 = counts in the totals, 0 = switched off
CREATE TABLE recurring_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  type TEXT NOT NULL,
  billing_cycle TEXT NOT NULL,
  payment_day INTEGER NOT NULL,
  start_month INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1
);
