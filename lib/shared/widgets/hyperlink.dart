import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class Hyperlink extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String text;
  final String? url;
  final Color? color;
  final TextStyle? textStyle;
  const Hyperlink({super.key, this.onTap, required this.text, this.color, this.textStyle, this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localColor = color ?? theme.colorScheme.primary;
    final localTextStyle = textStyle != null
        ? textStyle!.copyWith(color: localColor, decorationColor: localColor, decoration: TextDecoration.underline)
        : TextStyle(
            color: localColor, // Using primary color for consistency
            decorationColor: localColor,
            decoration: TextDecoration.underline,
          );
    return Link(
      uri: url != null ? Uri.parse(url!) : null,
      target: LinkTarget.blank,
      builder: (context, followLink) {
        return InkWell(
          onTap: onTap ?? followLink, // This triggers the URL launch
          child: Text(text, style: localTextStyle, softWrap: true),
        );
      },
    );
  }
}
