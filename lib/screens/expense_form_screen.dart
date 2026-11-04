import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/categories.dart';

/// The form for adding a new expense or editing an existing one.
///
/// If [expense] is null, the form starts empty and saving inserts a new row.
/// If [expense] is given, the form is pre-filled and saving updates that row.
/// The screen closes with the result `true` when something was saved.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  /// The expense to edit, or null to add a new one.
  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();

  String _category = categories.first.name;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    // Edit mode: copy the expense's values into the form.
    final expense = widget.expense;
    if (expense != null) {
      _amountController.text = _formatAmount(expense.amount);
      _titleController.text = expense.title;
      _category = categoryFor(expense.category).name;
      _date = expense.date;
    }
    _dateController.text = formatDate(_date);
  }

  @override
  void dispose() {
    // Controllers must be disposed to free their resources.
    _amountController.dispose();
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// Shows 60 instead of 60.0 when the amount is a whole number.
  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toString();
  }

  /// The title must not be empty.
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  /// The amount must be a valid number greater than 0.
  String? _validateAmount(String? value) {
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

  /// Opens the date picker. The last date allowed is today, so future dates
  /// can't be picked.
  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null) return; // the user pressed Cancel

    setState(() {
      _date = picked;
      _dateController.text = formatDate(picked);
    });
  }

  /// Checks the form, saves the expense to SQLite and goes back to the
  /// home screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true; // disables the button so it can't be pressed twice
    });

    final amount = double.parse(_amountController.text.trim());
    final title = _titleController.text.trim();
    final existing = widget.expense;

    if (existing == null) {
      // Add mode: insert a new row. SQLite gives it an id.
      await DatabaseHelper.instance.insertExpense(
        Expense(title: title, amount: amount, category: _category, date: _date),
      );
    } else {
      // Edit mode: keep the same id and replace the other fields.
      await DatabaseHelper.instance.updateExpense(
        existing.copyWith(
          title: title,
          amount: amount,
          category: _category,
          date: _date,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              autofocus: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '฿ ',
                border: OutlineInputBorder(),
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Lunch',
                border: OutlineInputBorder(),
              ),
              validator: _validateTitle,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.name,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  ),
              ],
              // The dropdown shows the new choice by itself; we only need to
              // remember it for saving, so no setState is needed.
              onChanged: (value) {
                if (value != null) _category = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              readOnly: true, // the date can only be set with the picker
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save Changes' : 'Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
