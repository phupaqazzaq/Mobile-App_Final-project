import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';

/// The form for adding a new expense or editing an existing one.
///
/// If [expense] is null, the form starts empty with the current date and time,
/// and saving inserts a new row. If [expense] is given, the form is pre-filled
/// and saving updates that row.
/// The screen closes with the result `true` when something was saved.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  /// The expense to edit, or null to add a new one.
  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

/// Holds what the user has entered in the form and saves it to the database.
class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();

  String _category = categories.first.name;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    // Edit mode: copy the expense's values into the form.
    final expense = widget.expense;
    if (expense != null) {
      _amountController.text = amountToText(expense.amount);
      _titleController.text = expense.title;
      _category = categoryFor(expense.category).name;
      _date = expense.date;
    }
    _dateController.text = formatDateTime(_date);
  }

  @override
  void dispose() {
    // Controllers must be disposed to free their resources.
    _amountController.dispose();
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// The title must not be empty.
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  /// Opens the date picker, then the time picker. The last date allowed is
  /// today, so future dates can't be picked.
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (pickedDate == null || !mounted) return; // the user pressed Cancel

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (pickedTime == null || !mounted) return; // the user pressed Cancel

    final picked = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // The time picker can't block times later today, so check it here.
    if (picked.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The time can't be in the future.")),
      );
      return;
    }

    setState(() {
      _date = picked;
      _dateController.text = formatDateTime(picked);
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
              validator: validateAmount,
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
              readOnly: true, // it can only be changed with the pickers
              onTap: _pickDateTime,
              decoration: const InputDecoration(
                labelText: 'Date & time',
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
