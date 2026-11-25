import 'package:flutter/material.dart';

import '../utils/app_style.dart';

/// The bar at the top of the two forms: a round white back button on the
/// left and the title in the middle, smaller than the big titles of the four
/// tabs.
AppBar buildFormAppBar(String title) {
  return AppBar(
    leadingWidth: 68,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      // BackButton closes the form, like the arrow it replaces. Center lets
      // it keep its round size instead of stretching to the bar's height.
      child: Center(child: BackButton(style: AppStyle.roundButton)),
    ),
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppStyle.ink,
    ),
    title: Text(title),
  );
}
