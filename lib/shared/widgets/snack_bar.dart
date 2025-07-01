import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackbarMessenger(BuildContext context, {required String message, SnackBarType type = SnackBarType.info}) {
  Color? color = switch (type) {
    SnackBarType.info => Colors.blueAccent[200],
    SnackBarType.success => Colors.greenAccent[400],
    SnackBarType.warning => Colors.orangeAccent,
    SnackBarType.error => Colors.redAccent,
  };

  IconData? icon = switch (type) {
    SnackBarType.info => Icons.info_outline,
    SnackBarType.success => Icons.check_circle_outline,
    SnackBarType.warning => Icons.warning_amber_outlined,
    SnackBarType.error => Icons.error_outline_outlined,
  };

  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      shape: Border.all(color: color!),
      backgroundColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      content: Row(spacing: 10, children: [Icon(icon, color: color), Text(message, style: TextStyle(color: color))]),
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

enum SnackBarType { info, success, warning, error }
