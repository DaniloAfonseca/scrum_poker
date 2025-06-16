import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/login/login_page.dart';
import 'package:scrum_poker/room_setup/main_page.dart';
import 'package:scrum_poker/room_setup/user_room_page.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/voting/room_page.dart';
import 'package:scrum_poker/shared/router/login_route.dart';
import 'package:scrum_poker/shared/router/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? authGuard(BuildContext context, GoRouterState state) {
  final auth = FirebaseAuth.instance;

  // If we receive the token we need to save in Session Storage.
  final token = state.uri.queryParameters['code'];
  if (token != null && token.isNotEmpty) {
    _saveTokenToSessionStorage(token);
  }

  if (auth.currentUser == null && !state.matchedLocation.startsWith(Routes.room)) {
    return Routes.login;
  }

  return null;
}

Future<void> _saveTokenToSessionStorage(String token) async {
  if (token.isEmpty) return;

  final response = await JiraServices().accessToken(token);

  final box = await Hive.openBox('ScrumPoker');

  await box.put('jiraToken', response.data['access_token']);
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
          final roomId = state.extra as String?;
          return UserRoomPage(roomId: roomId);
        },
      ),
    ],
  );
}
