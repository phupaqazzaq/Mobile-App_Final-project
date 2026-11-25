import 'package:flutter/material.dart';

/// The colors and corner sizes of the app's look: a warm off-white
/// background, white cards with large round corners, dark ink for titles and
/// main buttons, and NoPoverty's green for the + buttons.
class AppStyle {
  // Only static members: the class is never created.
  AppStyle._();

  /// The warm off-white behind every screen.
  static const Color canvas = Color(0xFFF4F1EB);

  /// Dark ink: titles, the navigation bar, selected chips and main buttons.
  static const Color ink = Color(0xFF17181C);

  /// Grey for secondary text, such as dates and the decimals of an amount.
  /// It keeps at least 4.5:1 contrast on white, on [canvas] and on the light
  /// category tints.
  static const Color muted = Color(0xFF575B62);

  /// Orange that is dark enough for text (Colors.orange text would be too
  /// light to read on white).
  static const Color darkOrange = Color(0xFFA84300);

  /// How round the corners of cards are.
  static const double cardRadius = 24;

  /// How round the corners of text fields are.
  static const double fieldRadius = 18;

  /// Round white icon buttons, such as the back button of the forms.
  static final ButtonStyle roundButton = IconButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: ink,
  );
}

/// The app's theme: Material 3 with NoPoverty's green seed color, restyled
/// with the colors above. Every widget that isn't styled by hand gets its look
/// from here.
ThemeData buildAppTheme() {
  // The Material 3 colors made from the green seed, with the generated
  // background colors swapped: off-white for screens, and white for cards,
  // menus, dialogs and date pickers.
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    surface: AppStyle.canvas,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
  );
  const fieldCorners = BorderRadius.all(Radius.circular(AppStyle.fieldRadius));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppStyle.canvas,

    // Big, bold, left-aligned screen titles on the off-white background.
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppStyle.canvas,
      foregroundColor: AppStyle.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      toolbarHeight: 72,
      titleTextStyle: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppStyle.ink,
      ),
    ),

    // White cards with large round corners and no shadow. Cards have no
    // margin of their own: each screen sets the space around them.
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppStyle.cardRadius)),
      ),
    ),

    // The + buttons: a large green circle, NoPoverty's brand color.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: const CircleBorder(),
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
      iconSize: 30,
    ),

    // Main buttons (Add Expense, Save): black pills.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppStyle.ink,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppStyle.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Pill-shaped choices (Fixed cost or Subscription, Monthly or Yearly):
    // black when selected, white otherwise.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppStyle.ink,
        selectedBackgroundColor: AppStyle.ink,
        selectedForegroundColor: Colors.white,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Text fields: white boxes with round corners and no outline. The label
    // stays inside the box, and the field being typed in gets a dark line
    // along its bottom edge.
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: const UnderlineInputBorder(
        borderRadius: fieldCorners,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderRadius: fieldCorners,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const UnderlineInputBorder(
        borderRadius: fieldCorners,
        borderSide: BorderSide(color: AppStyle.ink, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderRadius: fieldCorners,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderRadius: fieldCorners,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),

    // The Undo message: a dark rounded box floating above the list.
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppStyle.ink,
      actionTextColor: Color(0xFFA5D6A7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE9E5DD),
      space: 1,
      thickness: 1,
    ),
  );
}
