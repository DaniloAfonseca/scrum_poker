import 'package:go_router/go_router.dart';
import 'package:scrum_poker/login/login_page.dart';
import 'package:scrum_poker/shared/router/routes.dart';

final loginRoute = GoRoute(
  path: Routes.login,
  builder: (context, state) {
    final code = state.pathParameters['code'];

    return LoginPage();
  },
);
