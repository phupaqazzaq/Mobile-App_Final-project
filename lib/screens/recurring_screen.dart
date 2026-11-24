import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recurring_payment.dart';
import '../utils/formatters.dart';
import '../utils/motion.dart';
import '../widgets/recurring_tile.dart';
import '../widgets/rolling_amount.dart';
import '../widgets/savings_float.dart';
import 'recurring_form_screen.dart';

/// The Recurring tab: a header with the totals, then the fixed costs and the
/// subscriptions. The + button adds an item and tapping an item edits it.
class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

/// Loads the fixed costs and subscriptions, and handles add, edit and delete.
class _RecurringScreenState extends State<RecurringScreen> {
  final _db = DatabaseHelper.instance;

  /// Every fixed cost and subscription.
  List<RecurringPayment> _items = [];

  /// True until the first load from the database has finished.
  bool _isLoading = true;

  /// The id of the subscription that was just switched off. Its row shows
  /// how much that saves per year, then this goes back to null.
  int? _switchedOffId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads the items from the database and redraws the screen.
  Future<void> _loadData() async {
    final items = await _db.getRecurring();
    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  /// Opens the form. With an [item] the form edits it; without one it adds a
  /// new item. The form returns the item it saved, or null if nothing was
  /// saved.
  Future<void> _openForm([RecurringPayment? item]) async {
    final route = MaterialPageRoute<RecurringPayment>(
      builder: (context) => RecurringFormScreen(item: item),
    );
    final saved = await Navigator.push(context, route);
    if (saved == null) return; // closed without saving

    // Wait until the form has finished closing, so the user sees the totals
    // roll and the savings label float up.
    await route.completed;
    if (!mounted) return;

    // A subscription that was on and is now off shows what it saves.
    // Switching one back on only rolls the totals.
    final switchedOff =
        item != null &&
        item.isActive &&
        !saved.isActive &&
        saved.type == RecurringPayment.subscription;
    if (switchedOff && !Motion.isOff(context)) {
      _switchedOffId = saved.id;
    }
    _loadData();
  }

  /// Called after an item is swiped away: deletes it from the database and
  /// shows a SnackBar with an Undo button that puts it back.
  Future<void> _deleteItem(RecurringPayment item) async {
    // Dismissible needs the swiped item to leave the list straight away.
    setState(() {
      _items.remove(item);
    });

    await _db.deleteRecurring(item.id!);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${item.name}"'),
        // A SnackBar with a button stays open until tapped unless persist
        // is false. We want it to disappear by itself after a few seconds.
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Insert the same item again, keeping its old id.
            await _db.insertRecurring(item);
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixedCosts = _items
        .where((item) => item.type == RecurringPayment.fixed)
        .toList();
    final subscriptions = _items
        .where((item) => item.type == RecurringPayment.subscription)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // Space at the bottom so the + button doesn't cover the last item.
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                _buildHeader(fixedCosts, subscriptions),
                ..._buildSection('Fixed costs', fixedCosts),
                ..._buildSection('Subscriptions', subscriptions),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add recurring payment',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// The card with the three totals. Only active items count.
  Widget _buildHeader(
    List<RecurringPayment> fixedCosts,
    List<RecurringPayment> subscriptions,
  ) {
    final colors = Theme.of(context).colorScheme;
    final subscriptionsPerYear = subscriptions
        .where((item) => item.isActive)
        .fold(0.0, (sum, item) => sum + item.yearlyCost);

    return Card(
      color: colors.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            _buildTotal(
              'Fixed costs\nper month',
              RecurringPayment.totalMonthlyCost(fixedCosts),
            ),
            _buildTotal(
              'Subscriptions\nper month',
              RecurringPayment.totalMonthlyCost(subscriptions),
            ),
            _buildTotal('Subscriptions\nper year', subscriptionsPerYear),
          ],
        ),
      ),
    );
  }

  /// One of the three totals in the header card.
  Widget _buildTotal(String label, double amount) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          // Totals roll: when an item is added, edited, deleted or switched
          // on or off, the total counts to its new value (RollingAmount, the
          // same TweenAnimationBuilder as the Home total).
          RollingAmount(
            amount: amount,
            format: formatWholeBaht,
            style: textTheme.titleMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// A section title followed by its items, or a short note if it is empty.
  List<Widget> _buildSection(String title, List<RecurringPayment> items) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Nothing here yet. Tap + to add one.'),
        ),
      for (final item in items) _buildRow(item),
    ];
  }

  /// One item, which can be swiped to the left to delete it (Dismissible).
  Widget _buildRow(RecurringPayment item) {
    final row = Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      onDismissed: (_) => _deleteItem(item),
      child: RecurringTile(item: item, onTap: () => _openForm(item)),
    );
    if (item.id != _switchedOffId) return row;

    // A subscription that was just switched off: its yearly cost floats up
    // from the row with a few coins (SavingsFloat), then disappears.
    return Stack(
      clipBehavior: Clip.none, // the label floats above the row
      children: [
        row,
        Positioned.fill(
          // The label never blocks a tap on the rows under it.
          child: IgnorePointer(
            child: Center(
              child: SavingsFloat(
                yearlyAmount: item.yearlyCost,
                onDone: () => setState(() => _switchedOffId = null),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The red background with a trash icon that shows while swiping.
  Widget _buildDeleteBackground() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete, color: colors.onError),
    );
  }
}
