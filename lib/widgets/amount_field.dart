import 'package:flutter/material.dart';

import '../utils/app_style.dart';
import '../utils/formatters.dart';

/// The amount field of the forms: a large number in the middle of a white
/// box, with a round ฿ badge on its left and the label "Amount" above it.
/// It checks the amount with validateAmount, so it must be a number above 0.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.textInputAction,
  });

  final TextEditingController controller;

  /// True to put the cursor here (and open the keyboard) when the form opens.
  final bool autofocus;

  /// What the keyboard's action key does, e.g. go to the next field.
  final TextInputAction? textInputAction;

  /// The width of the ฿ badge with its space on the left.
  static const double _badgeWidth = 58;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppStyle.ink,
        fontSize: 40,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: 'Amount',
        // The label always sits at the top, centred above the number.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelAlignment: FloatingLabelAlignment.center,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        // The ฿ sign on a round badge on the left...
        prefixIcon: SizedBox(
          width: _badgeWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppStyle.canvas,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '฿',
                style: TextStyle(
                  color: AppStyle.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        // ...and an empty space of the same width on the right, so the
        // number stays in the middle of the box.
        suffixIcon: const SizedBox(width: _badgeWidth),
      ),
      validator: validateAmount,
    );
  }
}
