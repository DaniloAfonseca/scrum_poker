import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/login/login_page.dart';
import 'package:scrum_poker/room_setup/main_page.dart';
import 'package:scrum_poker/room_setup/user_room_page.dart';
import 'package:scrum_poker/voting/room_page.dart';
import 'package:scrum_poker/shared/router/login_route.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/models/user.dart' as u;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//TODO: Manage redirections here.
String? authGuard(BuildContext context, GoRouterState state) {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null && !state.matchedLocation.startsWith(Routes.room)) {
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
          return const MainPage();
        },
      ),
      loginRoute,
      GoRoute(
        path: Routes.redirect,
        builder: (context, state) {
          final roomId = state.uri.queryParameters['id'];
          return LoginPage();
        },
      ),
      GoRoute(
        path: Routes.room,
        builder: (context, state) {
          final roomId = state.uri.queryParameters['id'];
          return RoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: '${Routes.room}/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'];
          return RoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (context, state) {
          return MainPage();
        },
      ),
      GoRoute(
        path: Routes.editRoom,
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>;
          final roomId = map['roomId'] as String?;
          final user = map['user'] as u.User;
          return UserRoomPage(roomId: roomId, user: user);
        },
      ),
    ],
  );
}
