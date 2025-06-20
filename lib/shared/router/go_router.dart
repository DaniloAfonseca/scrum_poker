import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/login/login_page.dart';
import 'package:scrum_poker/room_setup/main_page.dart';
import 'package:scrum_poker/room_setup/user_room_page.dart';
import 'package:scrum_poker/voting/room_page.dart';
import 'package:scrum_poker/shared/router/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final auth = FirebaseAuth.instance;

  // If we receive the token we need to save in Session Storage.
  final authCode = state.uri.queryParameters['code'];
  if (authCode != null && authCode.isNotEmpty) {
    await _saveSessionStorage(authCode);
  }

  if (auth.currentUser == null && !state.matchedLocation.startsWith(Routes.room)) {
    return Routes.login;
  }

  return null;
}

Future<void> _saveSessionStorage(String authCode) async {
  if (authCode.isEmpty) return;

  try {
    Box box = await Hive.openBox('authCodeScrumPoker');

    await box.put('auth-code', authCode);

    box.close();
  } catch (e) {
    if (kDebugMode) {
      print('There was an error: $e');
    }
  }
}

class ManagerRouter {
  static final router = GoRouter(
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
          return LoginPage();
        },
      ),
      GoRoute(
        path: Routes.redirect,
        builder: (context, state) {
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
        path: Routes.home,
        builder: (context, state) {
          return MainPage();
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
