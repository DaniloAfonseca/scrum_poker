import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'package:scrum_poker/firebase_options.dart';
import 'package:scrum_poker/scrum_poker_app.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/managers/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setUrlStrategy(PathUrlStrategy());

  await SettingsManager().initialise();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(), // Provide the ThemeManager
      child: const ScrumPokerApp(),
    ),
  );
}


