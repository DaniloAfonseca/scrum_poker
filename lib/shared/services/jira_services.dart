import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scrum_poker/jira_authentication.dart';
import 'package:scrum_poker/shared/models/base_response.dart';
import 'package:scrum_poker/shared/models/jira_user.dart';

class JiraServices {
  Uri jiraApiUrl(String url) => Uri.parse('https://api.atlassian.com/$url');

  Future<BaseResponse<JiraUser>> getJiraUser(String token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Token is empty');
    }

    try {
      final response = await http.get(jiraApiUrl('me'), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final user = JiraUser.fromJson(responseBody);

        return BaseResponse<JiraUser>(success: true, message: 'Login successfully', data: user);
      } else {
        return BaseResponse(success: false, message: 'Error trying to get JIRA user');
      }
    } catch (e) {
      return BaseResponse(success: false, message: 'Error api call: $e');
    }
  }

  Future<BaseResponse> accessToken(token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Token is empty');
    }

    final response = await http.post(
      jiraApiUrl('oauth/token'),
      headers: {'Content-Type': 'application/json'},

      body: json.encode({
        "grant_type": "authorization_code",
        "client_id": JiraAuthentication.clientId2,
        "client_secret": JiraAuthentication.secret2,
        "code": token,
        "redirect_uri": "http://localhost:1010/redirect",
      }),
    );

    return BaseResponse(success: response.statusCode == 200, data: json.decode(response.body));
  }
}
