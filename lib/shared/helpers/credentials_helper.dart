import 'package:scrum_poker/shared/models/access_token.dart';
import 'package:scrum_poker/shared/managers/jira_credentials_manager.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';

Future<void> getCredentials(AccessToken access) async {
  final jiraServices = JiraServices();
  final jiraManager = JiraCredentialsManager();
  final userResponse = await jiraServices.getJiraUser(access.token!);
  final userData = userResponse.data!;
  final resourcesResponse = await jiraServices.getResources(access.token!);
  final resourcesData = resourcesResponse.data;

  final expireDate = DateTime.now().add(Duration(seconds: access.expires! - 300)).toString();

  await jiraManager.setCredentials(
    JiraCredentials.fromMap({
      'refresh-token': access.refreshToken,
      'access-token': access.token,
      'expire-date': expireDate,
      'account-id': userData.accountId,
      'email': userData.email,
      'cloud-id': resourcesData['id'],
      'avatar-url': userData.picture,
      'jira-url': resourcesData['url'],
    }),
  );
}
