import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// App entry point: starts the SpendWise app.
void main() {
  runApp(const SpendWiseApp());
}

/// The root widget. Sets up the Material 3 theme (green seed color) and
/// opens [HomeScreen] as the first screen.
class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const HomeScreen(),
    );
  }
}
