import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/recurring_payment.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';
import '../utils/motion.dart';
import '../widgets/recurring_tile.dart';
import '../widgets/rolling_amount.dart';
import '../widgets/savings_float.dart';
import 'recurring_form_screen.dart';

/// The Recurring tab: three tiles with the totals, then the fixed costs and
/// the subscriptions. The + button adds an item and tapping an item edits it.
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
              padding: const EdgeInsets.only(top: 4, bottom: 96),
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

  /// The three totals, each on its own tile. Only active items count. The
  /// yearly cost of the subscriptions is on a dark tile, so it stands out.
  Widget _buildHeader(
    List<RecurringPayment> fixedCosts,
    List<RecurringPayment> subscriptions,
  ) {
    final subscriptionsPerYear = subscriptions
        .where((item) => item.isActive)
        .fold(0.0, (sum, item) => sum + item.yearlyCost);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 10,
        children: [
          _buildTotal(
            'Fixed costs\nper month',
            RecurringPayment.totalMonthlyCost(fixedCosts),
          ),
          _buildTotal(
            'Subscriptions\nper month',
            RecurringPayment.totalMonthlyCost(subscriptions),
          ),
          _buildTotal(
            'Subscriptions\nper year',
            subscriptionsPerYear,
            dark: true,
          ),
        ],
      ),
    );
  }

  /// One of the three total tiles: the label, then the amount. A [dark] tile
  /// is ink with white text.
  Widget _buildTotal(String label, double amount, {bool dark = false}) {
    return Expanded(
      child: Card(
        color: dark ? AppStyle.ink : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: dark ? Colors.white70 : AppStyle.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Totals roll: when an item is added, edited, deleted or
              // switched on or off, the total counts to its new value
              // (RollingAmount, the same TweenAnimationBuilder as the Home
              // total). FittedBox shrinks a very large amount to fit the tile.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RollingAmount(
                  amount: amount,
                  format: formatWholeBaht,
                  style: TextStyle(
                    color: dark ? Colors.white : AppStyle.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A section title followed by its items, or a short note if it is empty.
  List<Widget> _buildSection(String title, List<RecurringPayment> items) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppStyle.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Nothing here yet. Tap + to add one.',
            style: TextStyle(color: AppStyle.muted),
          ),
        ),
      for (final item in items) _buildRow(item),
    ];
  }

  /// One item, which can be swiped to the left to delete it (Dismissible).
  Widget _buildRow(RecurringPayment item) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: _buildDeleteBackground(),
        onDismissed: (_) => _deleteItem(item),
        child: RecurringTile(item: item, onTap: () => _openForm(item)),
      ),
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

  /// The red rounded background with a trash icon that shows while swiping.
  Widget _buildDeleteBackground() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(AppStyle.cardRadius),
      ),
      child: Icon(Icons.delete, color: colors.onError),
    );
  }
}
