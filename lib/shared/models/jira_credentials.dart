import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

class JiraCredentials {
  String? authCode;
  String? refreshToken;
  String? accessToken;
  String? accountId;
  String? cloudId;
  String? expireDate;
  String? email;
  String? avatarUrl;

  JiraCredentials({this.authCode, this.refreshToken, this.accessToken, this.accountId, this.cloudId, this.expireDate, this.email, this.avatarUrl});

  factory JiraCredentials.fromMap(Map<String, dynamic> map) {
    return JiraCredentials(
      authCode: map['auth-code'] as String?,
      refreshToken: map['refresh-token'] as String?,
      accessToken: map['access-token'] as String?,
      accountId: map['account-id'] as String?,
      email: map['email'] as String?,
      cloudId: map['cloud-id'] as String?,
      expireDate: map['expire-date'] as String?,
      avatarUrl: map['avatar-url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auth-code': authCode,
      'refresh-token': refreshToken,
      'access-token': accessToken,
      'email': email,
      'account-id': accountId,
      'cloud-id': cloudId,
      'expire-date': expireDate,
      'avatar-url': avatarUrl,
    };
  }
}

class JiraCredentialsManager {
  static final JiraCredentialsManager _instance = JiraCredentialsManager._internal();
  factory JiraCredentialsManager() => _instance;
  JiraCredentialsManager._internal();

  static const String _boxName = 'ScrumPoker';
  static const String _credentialsKey = 'jira-credentials';

  Box? _box;

  JiraCredentials? _currentCredentials;

  bool _isInitialising = false;

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
    await _box!.put(_credentialsKey, credentials.toMap());
    _currentCredentials = credentials;
  }

  Future<void> clearCredentials() async {
    await initialise();
    await _box!.delete(_credentialsKey);
    _currentCredentials = null;
  }

  Future<void> _ensureCredentialsLoaded() async {
    if (_currentCredentials == null) {
      await initialise();
    }
  }

  JiraCredentials? get currentCredentials {
    _ensureCredentialsLoaded();
    return _currentCredentials;
  }
}
