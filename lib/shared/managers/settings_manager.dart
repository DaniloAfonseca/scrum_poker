import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static const String _boxName = 'ScrumPoker';
  static const String _credentialsKey = 'jira-credentials';

  Box? _box;
  bool _isInitialising = false;

  JiraCredentials? _currentCredentials;
  JiraCredentials? get currentCredentials => _currentCredentials;

  String? _jiraUrl;
  String? get jiraUrl => _jiraUrl;

  String? _storyPointFieldName;
  String? get storyPointFieldName => _storyPointFieldName;

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

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

      _jiraUrl = _box!.get('jiraUrl') ?? '';

      _storyPointFieldName = _box!.get('storyPointFieldName');

      final appUserMap = _box!.get('appUser');
      if (appUserMap != null) {
        final map = jsonDecode(jsonEncode(appUserMap));
        _appUser = AppUser.fromJson(map);
      }
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
    _box!.put('jiraUrl', value);
    _jiraUrl = value;
  }

  void updateStoryPointFieldName(String value) {
    _box!.put('storyPointFieldName', value);
    _storyPointFieldName = value;
  }

  void updateAppUser(AppUser value) {
    _box!.put('appUser', value.toJson());
    _appUser = value;
  }

  void deleteAppUser() {
    _box!.delete('appUser');
    _appUser = null;
  }
}
