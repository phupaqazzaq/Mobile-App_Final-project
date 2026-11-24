-- NoPoverty sample data: the example from our project proposal, which we
-- used for manual testing. Run schema.sql first.
--
-- The expenses are dated November 2026, so the app counts them as "this
-- month" only in November 2026. With today = 15 November 2026 the app shows:
--   - Food is 84% of daily spending (฿1,600 of ฿1,900)
--   - 80% of the Food budget is used with 15 days left
--   - Food is projected to reach ฿3,200, ฿1,200 over budget
--   - subscriptions cost ฿5,028 a year (Netflix, ฿419 a month)

INSERT INTO expenses (title, amount, category, date) VALUES
  ('Groceries', 1600, 'Food', '2026-11-03T12:30:00.000'),
  ('BTS top-up', 300, 'Transport', '2026-11-05T08:15:00.000');

INSERT INTO budgets (category, monthly_limit) VALUES
  ('Food', 2000),
  ('Transport', 600);

INSERT INTO recurring_payments
  (name, amount, category, type, billing_cycle, payment_day, start_month, is_active)
VALUES
  ('Phone bill', 299, 'Bills', 'fixed', 'monthly', 10, NULL, 1),
  ('Netflix', 419, 'Entertainment', 'subscription', 'monthly', 20, NULL, 1);
