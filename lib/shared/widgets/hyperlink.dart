import 'package:flutter/material.dart';

class Hyperlink extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String text;
  final Color hyperlinkColor;
  final Color textColor;
  final TextStyle? textStyle;
  const Hyperlink({super.key, this.onTap, required this.text, this.hyperlinkColor = Colors.blueAccent, this.textColor = Colors.black, this.textStyle});

  @override
  Widget build(BuildContext context) {
    final localTextStyle = textStyle ?? TextStyle();
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: localTextStyle.copyWith(
          color: Colors.transparent,
          shadows: [Shadow(color: textColor, offset: Offset(0, -3))],
          decoration: TextDecoration.underline,
          decorationColor: hyperlinkColor,
          decorationThickness: 1,
          decorationStyle: TextDecorationStyle.solid,
        ),
      ),
    );
  }
}
