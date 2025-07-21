import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadThemeMode(); // Load theme when manager is created
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0; // 0 for system, 1 for light, 2 for dark
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners(); // Notify listeners after loading
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // No change
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index); // Save the index
    notifyListeners(); // Rebuild widgets that depend on this
  }
}
