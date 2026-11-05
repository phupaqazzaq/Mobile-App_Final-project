import 'package:flutter/material.dart';

import 'budgets_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'recurring_screen.dart';

/// The app's main layout: the current tab with a NavigationBar underneath.
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
    // would make SnackBars cover the + button instead of pushing it up.
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
        NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Budgets',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_repeat_outlined),
              selectedIcon: Icon(Icons.event_repeat),
              label: 'Recurring',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
          ],
        ),
      ],
    );
  }
}
