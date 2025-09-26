import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';

const String _boxName = 'ScrumPoker';
const String _credentialsKey = 'jira-credentials';
const String _jiraUrlKey = 'jiraUrl';
const String _storyPointFieldNameKey = 'storyPointFieldName';
const String _autoFlipKey = 'autoFlip';
const String _appUserKey = 'appUser';
const String _themeModeKey = 'themeMode';

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  Box? _box;
  bool _isInitialising = false;

  JiraCredentials? _currentCredentials;
  JiraCredentials? get currentCredentials => _currentCredentials;

  String? _jiraUrl;
  String? get jiraUrl => _jiraUrl;

  String? _storyPointFieldName;
  String? get storyPointFieldName => _storyPointFieldName;

  bool _autoFlip = false;
  bool get autoFlip => _autoFlip;

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

  int _themeModeIndex = 1;
  int get themeModeIndex => _themeModeIndex;

  Future<void> initialise() async {
    if (_isInitialising) return;
    _isInitialising = true;

    try {
      if (_box == null || !_box!.isOpen) {
        _box = await Hive.openBox(_boxName);
      }

      final credentials = _box!.get(_credentialsKey);
      if (credentials != null) {
        _currentCredentials = JiraCredentials.fromMap(Map<String, dynamic>.from(credentials));
      } else {
        _currentCredentials = null;
      }

      _jiraUrl = _box!.get(_jiraUrlKey) ?? '';

      _storyPointFieldName = _box!.get(_storyPointFieldNameKey);

      _autoFlip = _box!.get(_autoFlipKey);

      final appUserMap = _box!.get(_appUserKey);
      if (appUserMap != null) {
        final map = jsonDecode(jsonEncode(appUserMap));
        _appUser = AppUser.fromJson(map);
      }

      _themeModeIndex = _box!.get(_themeModeKey) ?? 1;
    } catch (e) {
      if (kDebugMode) {
        print('Error initialising Jira Credentials: $e');
        _currentCredentials = null;
      }
    } finally {
      _isInitialising = false;
    }
  }

  Future<void> setCredentials(JiraCredentials credentials) async {
    await initialise();
    await _box!.delete(_credentialsKey);
    await _box!.put(_credentialsKey, credentials.toMap());
    _currentCredentials = credentials;
  }

  Future<void> clearCredentials() async {
    await initialise();
    await _box!.delete(_credentialsKey);
    _currentCredentials = null;
  }

  void updateJiraUrl(String value) {
    _box!.put(_jiraUrlKey, value);
    _jiraUrl = value;
  }

  void updateStoryPointFieldName(String value) {
    _box!.put(_storyPointFieldNameKey, value);
    _storyPointFieldName = value;
  }

  void updateAutoFlip(bool value) {
    _box!.put(_autoFlipKey, value);
    _autoFlip = value;
  }

  void updateAppUser(AppUser value) {
    _box!.put(_appUserKey, value.toJson());
    _appUser = value;
  }

  void updateThemeIndex(int value) {
    _box!.put(_themeModeKey, value);
    _themeModeIndex = value;
  }

  void deleteAppUser() {
    _box!.delete(_appUserKey);
    _appUser = null;
  }
}
