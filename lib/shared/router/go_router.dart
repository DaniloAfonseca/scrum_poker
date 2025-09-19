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
import 'package:scrum_poker/shared/pages/redirect_page.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/voting/room_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final auth = FirebaseAuth.instance;

  bool redirect = false;
  if (!state.matchedLocation.startsWith(Routes.room)) {
    if (auth.currentUser == null) {
      if ([Routes.register, Routes.login].contains(state.matchedLocation)) {
        return null;
      }
      redirect = true;
    } else {
      if (JiraCredentialsManager().currentCredentials != null) {
        final response = await JiraServices().checkCredentials();
        if (response != null) {
          SettingsManager().deleteAppUser();
          AuthServices().signOut();
          JiraCredentialsManager().clearCredentials();
          redirect = true;
        }
      }
    }
  }

  if (redirect) {
    final currentUri = state.uri;

    final redirectUri = Uri(path: Routes.redirect, queryParameters: currentUri.queryParameters);
    return redirectUri.toString();
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
              return CustomTransitionPage(
                transitionsBuilder: (context, firstAnimation, secondAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOutCirc).animate(firstAnimation),
                    child: child,
                  );
                },
                child: const LoginPage(),
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
        path: Routes.redirect,
        builder: (context, state) {
          final redirectCode = state.uri.queryParameters['code'];
          return RedirectPage(code: redirectCode);
        },
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
