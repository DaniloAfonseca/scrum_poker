import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/login/login_page.dart';
import 'package:scrum_poker/room_setup/main_page.dart';
import 'package:scrum_poker/room_setup/user_room_page.dart';
import 'package:scrum_poker/voting/room_page.dart';
import 'package:scrum_poker/shared/router/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final auth = FirebaseAuth.instance;

  if (auth.currentUser == null) {
    if (state.matchedLocation == Routes.login) {
      return null;
    }
    final currentUri = state.uri;

    final loginUri = Uri(path: Routes.login, queryParameters: currentUri.queryParameters);
    return loginUri.toString();
  }

  return null;
}

class ManagerRouter {
  static final goRouter = GoRouter(
    initialLocation: '/',
    redirect: authGuard,
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) {
          return const MainPage();
        },
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return LoginPage(authCode: code);
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
        path: Routes.editRoom,
        builder: (context, state) {
          final roomId = state.extra as String?;
          return UserRoomPage(roomId: roomId);
        },
      ),
    ],
  );
}
