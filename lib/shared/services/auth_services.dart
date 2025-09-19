import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scrum_poker/jira_authentication.dart';
import 'package:scrum_poker/shared/managers/jira_credentials_manager.dart';
import 'package:scrum_poker/shared/services/base_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthServices extends BaseServices {
  final auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in: $e');
      }
      return null;
    }
  }

  Future<void> signInWithCredentials(String email, String photoUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$firebaseApiUrl/generateTokeFromEmail'),
        body: json.encode({'email': email, 'photoUrl': photoUrl}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        return;
      }
      final customToken = jsonDecode(response.body)['token'];

      await auth.signInWithCustomToken(customToken);
    } catch (e) {
      return;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      return 'We\'ve sent an email to reset the password';
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'user-not-found') {
        message = 'The user with this email doesn\'t exist.';
      }
      return message;
    } catch (e) {
      if (kDebugMode) {
        print('There was an error: $e');
      }
      return null;
    }
  }

  Future<void> signInWithJira() async {
    final clientId = JiraAuthentication.clientId;
    //final clientSecret = JiraAuthentication.secret2;

    final redirectUri = Uri.encodeComponent('${Uri.base.origin}/redirect');
    final scope = Uri.encodeComponent(
      'offline_access read:me read:account read:jira-work manage:jira-project manage:jira-configuration read:jira-user write:jira-work manage:jira-webhook manage:jira-data-provider',
    );
    final state = 'random_string_to_protect_against_csrf';

    final authUrl =
        'https://auth.atlassian.com/authorize?audience=api.atlassian.com&client_id=$clientId&scope=$scope&redirect_uri=$redirectUri&state=$state&response_type=code&prompt=consent';

    final uri = Uri.parse(authUrl);

    await launchUrl(uri, webOnlyWindowName: '_self');
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      JiraCredentialsManager().clearCredentials();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
}
