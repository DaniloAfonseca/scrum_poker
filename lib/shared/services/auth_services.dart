import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scrum_poker/jira_authentication.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthServices {
  final String baseUrl = 'https://generatetokefromemail-fvxqqvi45a-uc.a.run.app';
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

  Future<void> signInWithCredentials(AppUser user) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/generateTokeFromEmail'), body: json.encode({'email': user.email}), headers: {'Content-Type': 'application/json'});

      if (response.statusCode != 200) {
        return;
      }
      final customToken = jsonDecode(response.body)['token'];

      await auth.signInWithCustomToken(customToken);
    } catch (e) {
      return;
    }
  }

  Future<void> signInWithJira() async {
    final clientId = JiraAuthentication.clientId2;
    //final clientSecret = JiraAuthentication.secret2;
    final redirectUri = Uri.encodeComponent('http://localhost:1010/redirect');
    final scope = Uri.encodeComponent(
      'offline_access read:me read:account read:jira-work manage:jira-project manage:jira-configuration read:jira-user write:jira-work manage:jira-webhook manage:jira-data-provider read:servicedesk-request manage:servicedesk-customer write:servicedesk-request read:servicemanagement-insight-objects',
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
      final box = await Hive.openBox('ScrumPoker');
      await box.delete('jiraToken');
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
}
