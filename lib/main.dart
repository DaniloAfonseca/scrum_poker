import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'package:scrum_poker/firebase_options.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setUrlStrategy(PathUrlStrategy());

  await JiraCredentialsManager().initialise();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(), // Provide the ThemeManager
      child: const ScrumPokerApp(),
    ),
  );
}

class ScrumPokerApp extends StatelessWidget {
  const ScrumPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        hintColor: Colors.grey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // Text color for AppBar
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue, brightness: Brightness.light).copyWith(secondary: Colors.amber), // Accent color
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(
            color: Colors.grey, // Color for label when it's inside (unfocused, no text)
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blue, width: 2.0)),
          filled: true,
          floatingLabelStyle: TextStyle(
            color: Colors.blueGrey, // Color for label when it's floating (focused or has text)
            fontSize: 14.0,
            fontWeight: FontWeight.normal,
          ),
          //fillColor: theme.primaryColor,
        )
      ),
      // Define your dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue, // Darker primary for dark mode
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // Dark AppBar background
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[900], // Dark background for scaffolds
        cardColor: Colors.grey[850], // Darker cards
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue, brightness: Brightness.dark).copyWith(secondary: Colors.tealAccent), // Accent color for dark mode
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(
            color: Colors.blueGrey.shade200, // Color for label when it's inside (unfocused, no text)
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.white, width: 2.0)),
          filled: true,
          floatingLabelStyle: TextStyle(
            color: Colors.white, // Color for label when it's floating (focused or has text)
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
          //fillColor: theme.primaryColor,
        ),
      ),
      // Use the system theme by default (light or dark based on OS setting)
      themeMode: themeManager.themeMode,
      routerConfig: ManagerRouter.goRouter,
    );
  }
}
