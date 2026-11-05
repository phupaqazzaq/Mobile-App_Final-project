import 'package:flutter/material.dart';

import 'screens/main_shell.dart';

/// App entry point: starts the NoPoverty app.
void main() {
  runApp(const NoPovertyApp());
}

/// The root widget. Sets up the Material 3 theme (green seed color) and
/// opens [MainShell], which holds the four tabs.
class NoPovertyApp extends StatelessWidget {
  const NoPovertyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoPoverty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MainShell(),
    );
  }
}
