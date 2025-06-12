import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:scrum_poker/jira_authentication.dart';
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

  Future<void> signInWithJira() async {
    final clientId = JiraAuthentication.clientId2;
    //final clientSecret = JiraAuthentication.secret2;
    final redirectUri = Uri.encodeComponent('http://localhost:1010/redirect');
    final scope = Uri.encodeComponent(
      'read:me read:account read:jira-work manage:jira-project manage:jira-configuration read:jira-user write:jira-work manage:jira-webhook manage:jira-data-provider',
    );
    final state = 'random_string_to_protect_against_csrf';

    final authUrl =
        'https://auth.atlassian.com/authorize?audience=api.atlassian.com&client_id=$clientId&scope=$scope&redirect_uri=$redirectUri&state=$state&response_type=code&prompt=consent';

    final uri = Uri.parse(authUrl);

    // Open new tab/window

    await launchUrl(uri, webOnlyWindowName: '_self');
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
}
