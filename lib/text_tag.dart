import 'package:flutter/material.dart';

class TextTag extends StatelessWidget {
  final bool display;
  final String text;
  final Color backgroundColor;
  final Color? borderColor;
  final Color foreColor;
  final double? width;
  final String? toolTipText;
  final FontWeight? fontWeight;
  final double? fontSize;
  final EdgeInsets? margin;
  const TextTag({
    super.key,
    this.display = true,
    required this.text,
    required this.backgroundColor,
    required this.foreColor,
    this.width,
    this.toolTipText,
    this.fontWeight,
    this.fontSize,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textToDisplay = Text(
      text,
      style: theme.textTheme.bodyMedium!.copyWith(color: foreColor, fontSize: fontSize, fontWeight: fontWeight),
      softWrap: true,
      textAlign: TextAlign.center,
    );
    final container = Container(
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        border: borderColor != null ? Border.all(color: borderColor ?? const Color(0xFF3A5856), width: 0.5, style: BorderStyle.solid) : null,
        borderRadius: BorderRadius.circular(4),
        color: backgroundColor,
      ),
      child: textToDisplay,
    );
    return Visibility(visible: display, child: toolTipText != null ? Tooltip(message: toolTipText, child: container) : container);
  }
}
