import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:scrum_poker/firebase_options.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';
import 'package:scrum_poker/shared/router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setUrlStrategy(PathUrlStrategy());

  await JiraCredentialsManager().initialise();

  runApp(const ScrumPokerApp());
}

class ScrumPokerApp extends StatelessWidget {
  const ScrumPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(debugShowCheckedModeBanner: false, routerConfig: ManagerRouter.router);
  }
}
