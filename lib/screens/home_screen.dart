import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/insight.dart';
import '../models/recurring_payment.dart';
import '../utils/categories.dart';
import '../widgets/expense_tile.dart';
import '../widgets/insight_card.dart';
import '../widgets/summary_card.dart';
import 'expense_form_screen.dart';
import 'insights_screen.dart';

/// The Home tab: the monthly summary card, the top suggestion, the category
/// filter chips and the list of expenses. The + button adds an expense.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSeeAllInsights});

  /// Called when "See all" is tapped on the top suggestion.
  final VoidCallback onSeeAllInsights;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Loads the expenses, totals and top suggestion, and handles the Home actions.
class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  /// The expenses shown in the list (already filtered by [_selectedCategory]).
  List<Expense> _expenses = [];

  /// This month's expenses, in all categories.
  double _dailySpending = 0;

  /// The monthly cost of the active fixed costs and subscriptions.
  double _recurringCost = 0;

  /// The most important suggestion, or null if there are none.
  Insight? _topInsight;

  /// The selected filter chip. null means "All".
  String? _selectedCategory;

  /// True until the first load from the database has finished.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads the list, this month's totals and the top suggestion from the
  /// database, then redraws the screen. Called when the tab opens and after
  /// every add, edit, delete or filter change.
  Future<void> _loadData() async {
    final now = DateTime.now();
    final category = _selectedCategory;
    final expenses = await _db.getExpenses(category: category);
    final totals = await _db.getCategoryTotals(now);
    final recurring = await _db.getRecurring();
    final insights = await loadInsights(now);

    // Stop if the screen was closed, or if the user picked another filter
    // while we were waiting (the newer load will show that one).
    if (!mounted || category != _selectedCategory) return;

    setState(() {
      _expenses = expenses;
      _dailySpending = totals.values.fold(0.0, (sum, total) => sum + total);
      _recurringCost = RecurringPayment.totalMonthlyCost(recurring);
      _topInsight = insights.isEmpty ? null : insights.first;
      _isLoading = false;
    });
  }

  /// Opens the form. With an [expense] the form edits it; without one it
  /// adds a new expense. The form returns true when it saved something.
  Future<void> _openForm([Expense? expense]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(expense: expense),
      ),
    );
    if (saved == true) {
      _loadData();
    }
  }

  /// Changes the category filter (null = All) and reloads the list.
  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadData();
  }

  /// Called after an expense is swiped away: deletes it from the database
  /// and shows a SnackBar with an Undo button that puts it back.
  Future<void> _deleteExpense(Expense expense) async {
    // Dismissible needs the swiped item to leave the list straight away.
    setState(() {
      _expenses.remove(expense);
    });

    await _db.deleteExpense(expense.id!);
    await _loadData();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${expense.title}"'),
        // A SnackBar with a button stays open until tapped unless persist
        // is false. We want it to disappear by itself after a few seconds.
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Insert the same expense again. It keeps its old id, so it goes
            // back to the same place in the list.
            await _db.insertExpense(expense);
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NoPoverty')),
      body: ListView.builder(
        // Space at the bottom so the + button doesn't cover the last item.
        padding: const EdgeInsets.only(bottom: 80),
        // The first item is the header, so everything scrolls together and
        // small screens never run out of room.
        itemCount: _expenses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader();

          final expense = _expenses[index - 1];
          // Dismissible lets the user swipe the item to the left to delete it.
          return Dismissible(
            key: ValueKey(expense.id),
            direction: DismissDirection.endToStart,
            background: _buildDeleteBackground(),
            onDismissed: (_) => _deleteExpense(expense),
            child: ExpenseTile(
              expense: expense,
              onTap: () => _openForm(expense),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Everything above the expenses, plus a spinner or the empty message when
  /// there are no expenses to show.
  Widget _buildHeader() {
    final topInsight = _topInsight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryCard(
          dailySpending: _dailySpending,
          recurringCost: _recurringCost,
          month: DateTime.now(),
        ),
        if (topInsight != null)
          InsightCard(insight: topInsight, onSeeAll: widget.onSeeAllInsights),
        _buildFilterChips(),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_expenses.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  /// A row of chips (All, Food, Transport, ...) that scrolls sideways.
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (_) => _selectCategory(null),
          ),
          for (final category in categories)
            ChoiceChip(
              label: Text(category.name),
              selected: _selectedCategory == category.name,
              onSelected: (_) => _selectCategory(category.name),
            ),
        ],
      ),
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

  /// Shown when there are no expenses to list.
  Widget _buildEmptyState() {
    final message = _selectedCategory == null
        ? 'No expenses yet. Tap + to add one.'
        : 'No $_selectedCategory expenses yet. Tap + to add one.';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
