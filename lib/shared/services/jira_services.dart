import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scrum_poker/jira_authentication.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/base_response.dart';

class JiraServices {
  Uri jiraApiAuthUrl(String url) => Uri.parse('https://api.atlassian.com/$url');
  String get jiraApiUrl => 'apotec.atlassian.net';

  Future<String> get accessJiraToken async {
    final box = await Hive.openBox('ScrumPoker');

    return box.get('jiraToken');
  }

  Future<BaseResponse<AppUser>> getJiraUser(String token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Token is empty');
    }

    try {
      final response = await http.get(jiraApiAuthUrl('me'), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final user = AppUser.fromJson(responseBody);

        return BaseResponse<AppUser>(success: true, message: 'Login successfully', data: user);
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
      jiraApiAuthUrl('oauth/token'),
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

  Future<BaseResponse> searchIssues({required String query, int maxResults = 20, List<String>? fields, int startAt = 0}) async {
    final accessToken = await accessJiraToken;

    if (accessToken.isEmpty) {
      return BaseResponse(success: false, message: 'Access Token is empty');
    }

    try {
      Uri uri = Uri.parse('$jiraApiUrl/rest/api/3/search').replace(
        queryParameters: {'jql': query, 'maxResults': maxResults.toString(), 'startAt': startAt.toString(), if (fields != null && fields.isNotEmpty) 'fields': fields.join(',')},
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken', 'X-Atlassian-Token': 'no-check', 'Accept': 'application/json', 'Content-Type': 'application/x-www-form-urlencoded'},
      );

      final data = json.encode(response.body);

      return BaseResponse(success: response.statusCode == 200, data: json.encode(response.body));
    } catch (e) {
      return BaseResponse(success: false, message: 'There was an error: $e');
    }
  }
}
