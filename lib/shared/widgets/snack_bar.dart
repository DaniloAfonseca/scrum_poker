import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/router/go_router.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackbarMessenger({required String message, SnackBarType type = SnackBarType.info}) {
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

  final context = navigatorKey.currentContext!;
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      clipBehavior: Clip.antiAlias,
      showCloseIcon: true,
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      elevation: 4.0,
      content: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          Flexible(
            child: Text(message, style: const TextStyle(color: Colors.white), softWrap: true),
          ),
        ],
      ),
      // action: SnackBarAction(
      //   label: 'Dismiss',
      //   onPressed: () {
      //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
      //   },
      // ),
    ),
  );
}

enum SnackBarType { info, success, warning, error }
