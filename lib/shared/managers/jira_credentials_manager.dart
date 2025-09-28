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
  final settingsManager = SettingsManager();

  /// Initialises jira credentials manager
  Future<void> initialise() async {
    if (_isInitialising) return;
    _isInitialising = true;

    try {
      await settingsManager.initialise();

      _currentCredentials = settingsManager.currentCredentials;
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

  /// Sets credentials
  /// 
  /// [credentials] the credentials to set
  Future<void> setCredentials(JiraCredentials credentials) async {
    await initialise();
    await settingsManager.setCredentials(credentials);
    _currentCredentials = credentials;
    isConnected.value = _currentCredentials != null;
  }

  /// Clears credentials
  Future<void> clearCredentials() async {
    await initialise();
    await settingsManager.clearCredentials();
    _currentCredentials = null;
    isConnected.value = _currentCredentials != null;
  }

  /// The current jira credentials
  JiraCredentials? get currentCredentials {
    return _currentCredentials;
  }
}
