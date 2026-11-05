import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recurring_payment.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/budget_tile.dart';

/// The Budgets tab: one row per category showing how much of its monthly
/// limit has been spent. Tapping a row sets or changes the limit.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

/// Loads each category's spending and limit, and opens the budget dialog.
class _BudgetsScreenState extends State<BudgetsScreen> {
  final _db = DatabaseHelper.instance;

  /// This month's expenses per category.
  Map<String, double> _totals = {};

  /// Every fixed cost and subscription.
  List<RecurringPayment> _recurring = [];

  /// The monthly limit per category. Categories without a budget are left out.
  Map<String, double> _budgets = {};

  /// True until the data has been read from the database.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads the totals, recurring payments and budgets from the database.
  Future<void> _loadData() async {
    final totals = await _db.getCategoryTotals(DateTime.now());
    final recurring = await _db.getRecurring();
    final budgets = await _db.getBudgets();
    if (!mounted) return;

    setState(() {
      _totals = totals;
      _recurring = recurring;
      _budgets = budgets;
      _isLoading = false;
    });
  }

  /// "Spent" for a category: its expenses this month plus the monthly cost of
  /// its recurring payments.
  double _spentIn(String category) {
    return (_totals[category] ?? 0) +
        RecurringPayment.totalMonthlyCost(_recurring, category: category);
  }

  /// Opens the dialog for a category's budget and reloads if something changed.
  Future<void> _editBudget(ExpenseCategory category) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _BudgetDialog(
        category: category.name,
        currentLimit: _budgets[category.name],
      ),
    );
    if (changed == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final category in categories)
                  BudgetTile(
                    category: category,
                    spent: _spentIn(category.name),
                    limit: _budgets[category.name],
                    onTap: () => _editBudget(category),
                  ),
              ],
            ),
    );
  }
}

/// The dialog that sets, changes or removes one category's monthly limit.
/// It closes with the result `true` when something was saved.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.category, required this.currentLimit});

  final String category;

  /// The limit before editing, or null if the category has no budget yet.
  final double? currentLimit;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

/// Checks the limit the user typed and saves or removes it in the database.
class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentLimit = widget.currentLimit;
    if (currentLimit != null) {
      _limitController.text = amountToText(currentLimit);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  /// Checks the limit, saves it and closes the dialog.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await DatabaseHelper.instance.setBudget(
      widget.category,
      double.parse(_limitController.text.trim()),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  /// Removes the budget and closes the dialog.
  Future<void> _remove() async {
    await DatabaseHelper.instance.deleteBudget(widget.category);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.category} budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _limitController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly limit',
            prefixText: '฿ ',
            border: OutlineInputBorder(),
          ),
          validator: validateAmount,
        ),
      ),
      actions: [
        if (widget.currentLimit != null)
          TextButton(onPressed: _remove, child: const Text('Remove budget')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
