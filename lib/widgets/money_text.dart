import 'package:flutter/material.dart';

/// Shows an amount that is already formatted, e.g. ฿2,618.00, as one Text.
///
/// With a [decimalsStyle], the ".00" part is drawn in that style (smaller and
/// grey), so the whole baht stand out: big bold numbers with small grey
/// decimals. An optional [prefix], e.g. "Daily spending ", comes first in
/// [prefixStyle].
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amountText, {
    super.key,
    this.style,
    this.decimalsStyle,
    this.prefix = '',
    this.prefixStyle,
  });

  /// The formatted amount, e.g. ฿2,618.00 from formatBaht.
  final String amountText;

  /// The style of the whole text.
  final TextStyle? style;

  /// The style of the decimals, added on top of [style]. If null, the
  /// decimals look like the rest of the amount.
  final TextStyle? decimalsStyle;

  /// Text in front of the amount, e.g. "Daily spending ".
  final String prefix;

  /// The style of [prefix], added on top of [style].
  final TextStyle? prefixStyle;

  @override
  Widget build(BuildContext context) {
    // Thai baht amounts use a dot before the decimals: ฿2,618 + .00
    final dot = amountText.lastIndexOf('.');
    final splitDecimals = decimalsStyle != null && dot != -1;

    // Text.rich draws several pieces of text with different styles as one
    // line, so it still reads (and is found in tests) as "฿2,618.00".
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix, style: prefixStyle),
          TextSpan(
            text: splitDecimals ? amountText.substring(0, dot) : amountText,
          ),
          if (splitDecimals)
            TextSpan(text: amountText.substring(dot), style: decimalsStyle),
        ],
      ),
    );
  }
}
