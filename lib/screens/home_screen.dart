import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/insight.dart';
import '../models/recurring_payment.dart';
import '../utils/categories.dart';
import '../utils/motion.dart';
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

  /// Finds the + button on screen, so the add form can grow out of it.
  final _fabKey = GlobalKey();

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

  /// The id of the expense that was just added. Its row slides into the list
  /// once, then this goes back to null.
  int? _newExpenseId;

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
  /// adds a new expense. The form returns the saved expense's id, or null if
  /// nothing was saved.
  Future<void> _openForm([Expense? expense]) async {
    // Adding grows the form out of the + button; editing uses the normal
    // page transition.
    final PageRoute<int> route = expense == null
        ? _revealRoute(const ExpenseFormScreen())
        : MaterialPageRoute(
            builder: (context) => ExpenseFormScreen(expense: expense),
          );
    final savedId = await Navigator.push(context, route);
    if (savedId == null) return; // closed without saving

    // Wait until the form has finished closing, so the new row sliding in
    // and the rolling totals aren't hidden behind it.
    await route.completed;
    if (!mounted) return;

    if (expense == null) _newExpenseId = savedId;
    _loadData();
  }

  /// + button opens into the form: a circular reveal. PageRouteBuilder lets
  /// us write our own transition, and ClipPath shows only the part of the
  /// form inside a circle around the + button. The circle's radius grows from
  /// 0 to the screen's diagonal in 450 ms (see _CircleRevealClipper), and
  /// shrinks back into the button when the form closes.
  PageRouteBuilder<int> _revealRoute(Widget page) {
    final center = _fabCenter();
    final duration = Motion.duration(context, Motion.reveal);

    return PageRouteBuilder<int>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ClipPath(
          clipper: _CircleRevealClipper(center: center, animation: animation),
          child: child,
        );
      },
    );
  }

  /// The middle of the + button on the screen.
  Offset _fabCenter() {
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      // The button isn't laid out (this shouldn't happen): use the
      // bottom-right corner of the screen.
      final size = MediaQuery.sizeOf(context);
      return Offset(size.width, size.height);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
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
          Widget tile = ExpenseTile(
            expense: expense,
            onTap: () => _openForm(expense),
          );
          if (expense.id == _newExpenseId) {
            tile = _slideIn(tile);
          }
          // Dismissible lets the user swipe the item to the left to delete
          // it, with its own slide-away animation.
          return Dismissible(
            key: ValueKey(expense.id),
            direction: DismissDirection.endToStart,
            background: _buildDeleteBackground(),
            onDismissed: (_) => _deleteExpense(expense),
            child: tile,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => _openForm(),
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// New expense slides in: the row that was just added fades in while it
  /// slides down into its place, 300 ms. TweenAnimationBuilder runs a value
  /// from 0 to 1 once; when it ends, the id is forgotten, so the row doesn't
  /// slide in again later.
  Widget _slideIn(Widget tile) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.duration(context, Motion.newItem),
      curve: Motion.curve,
      onEnd: () => _newExpenseId = null,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          // At 0 the row sits one row higher; at 1 it is in its place.
          child: FractionalTranslation(
            translation: Offset(0, value - 1),
            child: child,
          ),
        );
      },
      child: tile,
    );
  }

  /// Everything above the expenses, plus a spinner or the empty message when
  /// there are no expenses to show.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryCard(
          dailySpending: _dailySpending,
          recurringCost: _recurringCost,
          month: DateTime.now(),
        ),
        _buildBanner(),
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

  /// Suggestion banner: the top suggestion fades and slides up into place
  /// when the tab loads, 400 ms. AnimatedSwitcher does this whenever its
  /// child changes: from nothing to a card, or from one suggestion to
  /// another. AnimatedSize around it lets the chips below glide to their new
  /// place instead of jumping.
  Widget _buildBanner() {
    final topInsight = _topInsight;
    final duration = Motion.duration(context, Motion.banner);

    return AnimatedSize(
      duration: duration,
      curve: Motion.curve,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Motion.curve,
        switchOutCurve: Motion.curve,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: topInsight == null
            ? const SizedBox.shrink()
            : InsightCard(
                // A new key tells AnimatedSwitcher the suggestion changed.
                key: ValueKey('${topInsight.title}: ${topInsight.message}'),
                insight: topInsight,
                onSeeAll: widget.onSeeAllInsights,
              ),
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

/// Clips the add form to a circle around [center] (the + button). The circle
/// grows from nothing to the screen's diagonal as [animation] runs from 0 to
/// 1, so it covers the whole screen from any starting point.
class _CircleRevealClipper extends CustomClipper<Path> {
  // reclip makes Flutter ask for a new clip every time the animation moves.
  _CircleRevealClipper({required this.center, required this.animation})
    : super(reclip: animation);

  final Offset center;
  final Animation<double> animation;

  @override
  Path getClip(Size size) {
    final diagonal = Offset(size.width, size.height).distance;
    final radius = diagonal * Motion.curve.transform(animation.value);
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.animation != animation;
  }
}
