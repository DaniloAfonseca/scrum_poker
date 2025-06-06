import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/dashboard/dashboard.dart';
import 'package:scrum_poker/dashboard/user_room_editor.dart';
import 'package:scrum_poker/login/login_screen.dart';
import 'package:scrum_poker/room_screen.dart';
import 'package:scrum_poker/shared/router/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? authGuard(BuildContext context, GoRouterState state) {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    return Routes.login;
  }
  return null;
}

class ManagerRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: authGuard,
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const Dashboard();
        },
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) {
          return LoginPage();
        },
      ),
      GoRoute(
        path: Routes.room,
        builder: (context, state) {
          return RoomScreen();
        },
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (context, state) {
          return Dashboard();
        },
      ),
      GoRoute(
        path: Routes.editRoom,
        builder: (context, state) {
          return UserRoomEditor(roomId: state.extra as String?);
        },
      ),
    ],
  );
}
