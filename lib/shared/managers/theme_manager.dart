import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  /// Initialises theme manager
  void initialise() {
    _loadThemeMode(); // Load theme when manager is created
  }

  /// Loads theme mode
  Future<void> _loadThemeMode() async {
    final themeModeIndex = SettingsManager().themeModeIndex; // 0 for system, 1 for light, 2 for dark
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners(); // Notify listeners after loading
  }

  /// Sets theme mode
  /// 
  /// [mode] mode to be set
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // No change
    _themeMode = mode;
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt('themeMode', mode.index); // Save the index
    SettingsManager().updateThemeIndex(mode.index);
    notifyListeners(); // Rebuild widgets that depend on this
  }
}
