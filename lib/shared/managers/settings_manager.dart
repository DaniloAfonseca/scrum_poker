import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';
import 'package:web/web.dart' as web;

const String _boxName = 'ScrumPoker';
const String _credentialsKey = 'jira-credentials';
const String _jiraUrlKey = 'jiraUrl';
const String _storyPointFieldNameKey = 'storyPointFieldName';
const String _autoFlipKey = 'autoFlip';
const String _appUserKey = 'appUser';
const String _themeModeKey = 'themeMode';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  Box? _box;
  bool _isInitialising = false;

  JiraCredentials? _currentCredentials;
  JiraCredentials? get currentCredentials => _currentCredentials;

  final values = <String, dynamic>{_storyPointFieldNameKey: null, _autoFlipKey: false};

  String? _jiraUrl;
  String? get jiraUrl => _jiraUrl;

  String? get storyPointFieldName => values[_storyPointFieldNameKey];

  bool get autoFlip => values[_autoFlipKey];

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

  int _themeModeIndex = 1;
  int get themeModeIndex => _themeModeIndex;

  /// Initialises settings manager
  Future<void> initialise() async {
    if (_isInitialising) return;
    _isInitialising = true;

    try {
      if (_box == null || !_box!.isOpen) {
        _box = await Hive.openBox(_boxName, crashRecovery: true);
      }

      final credentials = _box!.get(_credentialsKey);
      if (credentials != null) {
        _currentCredentials = JiraCredentials.fromMap(Map<String, dynamic>.from(credentials));
      } else {
        _currentCredentials = null;
      }

      _jiraUrl = _box!.get(_jiraUrlKey) ?? '';

      final appUserMap = _box!.get(_appUserKey);
      if (appUserMap != null) {
        final map = jsonDecode(jsonEncode(appUserMap));
        _appUser = AppUser.fromJson(map);
      }

      _themeModeIndex = _box!.get(_themeModeKey) ?? 1;

      setValues();

      _box!.watch().listen((BoxEvent event) {
        setValues();
      });

      web.window.onstorage = (JSAny data) {
        final event = data as JSObject;

        // Access the 'key' property, which is a JavaScript string.
        final key = event.getProperty('key'.toJS) as JSString;
        // Access the 'newValue' property (this is the value you set)
        final value = event.getProperty('newValue'.toJS) as JSString?;

        // Convert key to a Dart String
        final dartKey = key.toDart;

        // Convert value to a Dart String
        final dartValue = value?.toDart;

        final settingToUpdate = SettingsValueEnum.values.firstWhereOrNull((t) => t.key == dartKey);
        if (settingToUpdate != null) {
          final valueToUpdate = dartValue == null || dartValue.isEmpty
              ? settingToUpdate.defaultValue
              : settingToUpdate.type == bool
              ? bool.parse(dartValue)
              : dartValue;
          values[dartKey] = valueToUpdate;
          _box!.put(dartKey, valueToUpdate);
          notifyListeners();
        }
      }.toJS;
    } catch (e) {
      if (kDebugMode) {
        print('Error initialising Jira Credentials: $e');
        _currentCredentials = null;
      }
    } finally {
      _isInitialising = false;
    }
  }

  /// Sets settings values
  void setValues() {
    bool hasValuesChanged = false;
    for (SettingsValueEnum enumValue in SettingsValueEnum.values) {
      if (values[enumValue.key] != _box!.get(enumValue.key)) {
        values[enumValue.key] = _box!.get(enumValue.key) ?? enumValue.defaultValue;
        hasValuesChanged = true;
      }
    }

    if (hasValuesChanged) {
      notifyListeners();
    }
  }

  /// Sets credentials value and update hive
  ///
  /// [credentials] credentials to be saved in hive
  Future<void> setCredentials(JiraCredentials credentials) async {
    await initialise();
    await _box!.delete(_credentialsKey);
    await _box!.put(_credentialsKey, credentials.toMap());
    _currentCredentials = credentials;
  }

  /// remove credentials from hive
  Future<void> clearCredentials() async {
    await initialise();
    await _box!.delete(_credentialsKey);
    _currentCredentials = null;
  }

  /// Updates jira url
  ///
  /// [value] the URL value
  void updateJiraUrl(String value) {
    _box!.put(_jiraUrlKey, value);
    _jiraUrl = value;
  }

  /// Updates current app user
  ///
  /// [value] the app user
  void updateAppUser(AppUser value) {
    _box!.put(_appUserKey, value.toJson());
    _appUser = value;
  }

  /// Updates theme
  ///
  /// [value] the theme value to be used
  void updateThemeIndex(int value) {
    _box!.put(_themeModeKey, value);
    _themeModeIndex = value;
  }

  /// Updates settings values
  ///
  /// [setting] the setting enum value
  /// [value] the value to set
  void updateSettingValue<T>(SettingsValueEnum setting, T value) {
    _box!.put(setting.key, value);
    web.window.localStorage.setItem(setting.key, value.toString());
  }

  /// Deletes current user
  void deleteAppUser() {
    _box!.delete(_appUserKey);
    _appUser = null;
  }

  @override
  void dispose() {
    _box = null;
    super.dispose();
  }
}

enum SettingsValueEnum {
  storyPointsField(_storyPointFieldNameKey, null, String),
  autoFlip(_autoFlipKey, false, bool);

  const SettingsValueEnum(this.key, this.defaultValue, this.type);

  final String key;
  final dynamic defaultValue;
  final Type type;
}
