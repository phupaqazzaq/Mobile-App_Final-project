import 'package:flutter/material.dart';

import '../widgets/pill_nav_bar.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'recurring_screen.dart';

/// The app's main layout: the current tab with the floating pill navigation
/// bar (PillNavBar) underneath.
///
/// Only the current tab exists at any time. Each tab reads its data in
/// initState, so switching tabs always shows fresh totals, budgets and
/// suggestions. A tab also reloads itself after it changes something.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

/// Remembers which of the four tabs is selected.
class _MainShellState extends State<MainShell> {
  static const int _insightsTab = 3;

  int _tabIndex = 0;

  /// Switches to another tab.
  void _selectTab(int index) {
    // Close any Undo SnackBar: Undo only refreshes the tab it came from.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _tabIndex = index;
    });
  }

  /// Creates the screen of the current tab.
  Widget _buildCurrentTab() {
    return switch (_tabIndex) {
      0 => HomeScreen(onSeeAllInsights: () => _selectTab(_insightsTab)),
      1 => const BudgetsScreen(),
      2 => const RecurringScreen(),
      _ => const InsightsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Each tab has its own Scaffold, with its own AppBar and + button. The bar
    // sits below it in a Column, because a second Scaffold around the tabs
    // would make SnackBars cover the + button instead of moving it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // The bar already keeps clear of the phone's navigation buttons, so
          // the tab above it doesn't have to.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: _buildCurrentTab(),
          ),
        ),
        PillNavBar(
          selectedIndex: _tabIndex,
          onSelected: _selectTab,
          items: const [
            PillNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            PillNavItem(
              icon: Icons.savings_outlined,
              selectedIcon: Icons.savings,
              label: 'Budgets',
            ),
            PillNavItem(
              icon: Icons.event_repeat_outlined,
              selectedIcon: Icons.event_repeat,
              label: 'Recurring',
            ),
            PillNavItem(
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights,
              label: 'Insights',
            ),
          ],
        ),
      ],
    );
  }
}
