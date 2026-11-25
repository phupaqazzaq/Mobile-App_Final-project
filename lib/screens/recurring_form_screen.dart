import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recurring_payment.dart';
import '../utils/app_style.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/amount_field.dart';
import '../widgets/category_icon.dart';
import '../widgets/form_app_bar.dart';

/// The form for adding a new fixed cost or subscription, or editing one.
///
/// If [item] is null, the form starts empty and saving inserts a new row.
/// If [item] is given, the form is pre-filled and saving updates that row.
/// The screen closes with the item it saved (for a new item, without its id).
class RecurringFormScreen extends StatefulWidget {
  const RecurringFormScreen({super.key, this.item});

  /// The item to edit, or null to add a new one.
  final RecurringPayment? item;

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

/// Holds what the user has entered in the form and saves it to the database.
class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController();

  String _category = 'Bills';
  String _type = RecurringPayment.fixed;
  String _billingCycle = RecurringPayment.monthly;
  int _startMonth = DateTime.now().month;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    // Edit mode: copy the item's values into the form.
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _amountController.text = amountToText(item.amount);
      _dayController.text = item.paymentDay.toString();
      _category = categoryFor(item.category).name;
      _type = item.type;
      _billingCycle = item.billingCycle;
      _startMonth = item.startMonth ?? _startMonth;
      _isActive = item.isActive;
    }
  }

  @override
  void dispose() {
    // Controllers must be disposed to free their resources.
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  /// The name must not be empty.
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a name';
    }
    return null;
  }

  /// The payment day must be from 1 to 28, a day that every month has.
  String? _validateDay(String? value) {
    final day = int.tryParse(value?.trim() ?? '');
    if (day == null || day < 1 || day > 28) {
      return 'Please enter a day from 1 to 28';
    }
    return null;
  }

  /// Checks the form, saves the item to SQLite and goes back to the list.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true; // disables the button so it can't be pressed twice
    });

    final item = RecurringPayment(
      id: widget.item?.id, // null in add mode, so SQLite gives it an id
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      type: _type,
      billingCycle: _billingCycle,
      paymentDay: int.parse(_dayController.text.trim()),
      startMonth: _billingCycle == RecurringPayment.yearly ? _startMonth : null,
      isActive: _isActive,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateRecurring(item);
    } else {
      await DatabaseHelper.instance.insertRecurring(item);
    }

    if (!mounted) return;
    // Give the list the saved item, so it can tell whether a subscription was
    // just switched off.
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildFormAppBar(
        _isEditing ? 'Edit Recurring Payment' : 'Add Recurring',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Phone bill or Netflix',
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 12),
            // The amount, large and centred, like on the expense form.
            AmountField(controller: _amountController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(AppStyle.fieldRadius),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.name,
                    child: Row(
                      children: [
                        CategoryIcon(category: category, size: 28),
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
            // Pill buttons: the selected choice is black (see the theme).
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: RecurringPayment.fixed,
                  label: Text('Fixed cost'),
                ),
                ButtonSegment(
                  value: RecurringPayment.subscription,
                  label: Text('Subscription'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: RecurringPayment.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: RecurringPayment.yearly,
                  label: Text('Yearly'),
                ),
              ],
              selected: {_billingCycle},
              onSelectionChanged: (selection) {
                setState(() {
                  _billingCycle = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            // A yearly item is paid in one month, so ask which one.
            if (_billingCycle == RecurringPayment.yearly) ...[
              DropdownButtonFormField<int>(
                initialValue: _startMonth,
                decoration: const InputDecoration(labelText: 'Payment month'),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(AppStyle.fieldRadius),
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(formatMonthName(month)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _startMonth = value;
                },
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment day',
                hintText: '1 to 28',
              ),
              validator: _validateDay,
            ),
            const SizedBox(height: 12),
            // The switch sits on a white card, like the fields above it.
            Card(
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: const Text(
                  'Active',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Inactive items don\'t count in any total',
                  style: TextStyle(color: AppStyle.muted),
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            // The main button: a black pill.
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Save Changes' : 'Add Recurring'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
