import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/auth/auth_page.dart';
import 'package:scrum_poker/auth/login_page.dart';
import 'package:scrum_poker/auth/register_page.dart';
import 'package:scrum_poker/room_setup/main_page.dart';
import 'package:scrum_poker/room_setup/edit_room_page.dart';
import 'package:scrum_poker/settings_page.dart';
import 'package:scrum_poker/shared/managers/jira_credentials_manager.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/voting/room_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final auth = FirebaseAuth.instance;

  bool redirectToLogin = false;
  if (!state.matchedLocation.startsWith(Routes.room)) {
    if (auth.currentUser == null) {
      if ([Routes.register, Routes.login].contains(state.matchedLocation)) {
        return null;
      }
      redirectToLogin = true;
    } else {
      if (JiraCredentialsManager().currentCredentials != null) {
        final response = await JiraServices().checkCredentials();
        if (response != null) {
          SettingsManager().deleteAppUser();
          AuthServices().signOut();
          JiraCredentialsManager().clearCredentials();
          redirectToLogin = true;
        }
      }
    }
  }

  if (redirectToLogin) {
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
      ShellRoute(
        builder: (context, state, child) => AuthPage(child: child),
        routes: [
          GoRoute(
            path: Routes.login,
            pageBuilder: (context, state) {
              final code = state.uri.queryParameters['code'];
              return CustomTransitionPage(
                transitionsBuilder: (context, firstAnimation, secondAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOutCirc).animate(firstAnimation),
                    child: child,
                  );
                },
                child: LoginPage(authCode: code),
              );
            },
          ),
          GoRoute(
            path: Routes.register,
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                transitionsBuilder: (context, firstAnimation, secondAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOutCirc).animate(firstAnimation),
                    child: child,
                  );
                },
                child: const RegisterPage(),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: Routes.room,
        builder: (context, state) {
          final roomId = state.uri.queryParameters['id'];
          return EditRoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: '${Routes.room}/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: Routes.editRoom,
        builder: (context, state) {
          final roomId = state.extra as String?;
          return EditRoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: '${Routes.editRoom}/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return EditRoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) {
          return const SettingsPage();
        },
      ),
    ],
  );
}
