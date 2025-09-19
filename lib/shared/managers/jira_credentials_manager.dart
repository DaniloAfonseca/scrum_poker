import 'package:flutter/foundation.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';

class JiraCredentialsManager {
  static final JiraCredentialsManager _instance = JiraCredentialsManager._internal();
  factory JiraCredentialsManager() => _instance;
  JiraCredentialsManager._internal();

  JiraCredentials? _currentCredentials;

  bool _isInitialising = false;

  final isConnected = ValueNotifier<bool>(false);

  Future<void> initialise() async {
    if (_isInitialising) return;
    _isInitialising = true;

    try {
      await SettingsManager().initialise();

      _currentCredentials = SettingsManager().currentCredentials;
    } catch (e) {
      if (kDebugMode) {
        print('Error initialising Jira Credentials: $e');
        _currentCredentials = null;
      }
    } finally {
      _isInitialising = false;
      isConnected.value = _currentCredentials != null;
    }
  }

  Future<void> setCredentials(JiraCredentials credentials) async {
    await initialise();
    await SettingsManager().setCredentials(credentials);
    _currentCredentials = credentials;
    isConnected.value = _currentCredentials != null;
  }

  Future<void> clearCredentials() async {
    await initialise();
    await SettingsManager().clearCredentials();
    _currentCredentials = null;
    isConnected.value = _currentCredentials != null;
  }

  JiraCredentials? get currentCredentials {
    return _currentCredentials;
  }
}
