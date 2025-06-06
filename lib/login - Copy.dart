import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scrum_poker/jira_authentication.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: ElevatedButton.icon(onPressed: () => launchJiraOAuth(), label: Text('Login'), icon: Icon(Icons.access_alarm))));
  }

  Future<void> launchJiraOAuth() async {
    final clientId = JiraAuthentication.clientId;
    final redirectUri = Uri.encodeComponent('https://yourapp.com/callback');
    final scope = Uri.encodeComponent('read:jira-user read:jira-work write:jira-work');
    final state = 'random_string_to_protect_against_csrf';

    final authUrl =
        'https://auth.atlassian.com/authorize?audience=api.atlassian.com&client_id=$clientId&scope=$scope&redirect_uri=$redirectUri&state=$state&response_type=code&prompt=consent';

    final Uri uri = Uri.parse(authUrl);
    // Open new tab/window
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
