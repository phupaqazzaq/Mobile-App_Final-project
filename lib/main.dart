import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'utils/app_style.dart';

/// App entry point: starts the NoPoverty app.
void main() {
  runApp(const NoPovertyApp());
}

/// The root widget. Sets up the Material 3 theme (green seed color, see
/// utils/app_style.dart) and opens [MainShell], which holds the four tabs.
class NoPovertyApp extends StatelessWidget {
  const NoPovertyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoPoverty',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}
