import 'package:flutter/material.dart';

import '../utils/categories.dart';

/// A category's icon in white on a square with round corners (or on a
/// circle), filled with the category's color from utils/categories.dart.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
    this.circle = false,
  });

  final ExpenseCategory category;

  /// The width and height of the square, in pixels.
  final double size;

  /// True for a circle instead of a square (the budget envelopes use it).
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        // A circle can't have corners, so only the square gets them.
        borderRadius: circle ? null : BorderRadius.circular(size * 0.3),
      ),
      child: Icon(category.icon, color: Colors.white, size: size * 0.52),
    );
  }
}
