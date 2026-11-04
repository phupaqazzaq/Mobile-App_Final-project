import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/categories.dart';
import '../widgets/expense_tile.dart';
import '../widgets/summary_card.dart';
import 'chart_screen.dart';
import 'expense_form_screen.dart';

/// The main screen: the monthly total card, the category filter chips and
/// the list of expenses. The + button adds an expense and the chart icon in
/// the AppBar opens the spending chart.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  /// The expenses shown in the list (already filtered by [_selectedCategory]).
  List<Expense> _expenses = [];

  /// Total spent in the current month, in all categories.
  double _monthlyTotal = 0;

  /// The selected filter chip. null means "All".
  String? _selectedCategory;

  /// True until the first load from the database has finished.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads the list and this month's total from the database, then redraws
  /// the screen. Called at startup and after every add, edit, delete or
  /// filter change.
  Future<void> _loadData() async {
    final category = _selectedCategory;
    final expenses = await _db.getExpenses(category: category);
    final total = await _db.getMonthlyTotal(DateTime.now());

    // Stop if the screen was closed, or if the user picked another filter
    // while we were waiting (the newer load will show that one).
    if (!mounted || category != _selectedCategory) return;

    setState(() {
      _expenses = expenses;
      _monthlyTotal = total;
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

  /// Opens the pie chart screen.
  void _openChart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChartScreen()),
    );
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
      appBar: AppBar(
        title: const Text('SpendWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Spending chart',
            onPressed: _openChart,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryCard(total: _monthlyTotal, month: DateTime.now()),
          _buildFilterChips(),
          Expanded(child: _buildExpenseList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
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

  /// The expense list, or a spinner while loading, or the empty message.
  Widget _buildExpenseList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_expenses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      // Space at the bottom so the + button doesn't cover the last item.
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        // Dismissible lets the user swipe the item to the left to delete it.
        return Dismissible(
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          background: _buildDeleteBackground(),
          onDismissed: (_) => _deleteExpense(expense),
          child: ExpenseTile(expense: expense, onTap: () => _openForm(expense)),
        );
      },
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
