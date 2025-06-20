import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scrum_poker/jira_authentication.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/base_response.dart';
import 'package:scrum_poker/shared/services/base_services.dart';

class JiraServices extends BaseServices {
  Uri jiraApiAuthUrl(String url) => Uri.parse('https://api.atlassian.com/$url');

  //String get jiraApiUrl => 'https://api.atlassian.com/ex/jira/e2969eda-f627-4429-ae2f-be8262224890';

  Future<String> get accessJiraToken async {
    final box = await Hive.openBox('ScrumPoker');

    return box.get('jiraToken');
  }

  Future<String> get accountId async {
    final box = await Hive.openBox('ScrumPoker');

    return box.get('accountId');
  }

  Future<String> get email async {
    final box = await Hive.openBox('ScrumPoker');
    return box.get('email');
  }

  Future<BaseResponse<AppUser>> getJiraUser(String token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Token is empty');
    }

    try {
      final response = await http.get(jiraApiUrl('me'), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        return BaseResponse<AppUser>(success: true, message: 'Login successfully', data: AppUser.fromJson(responseBody));
      } else {
        return BaseResponse(success: false, message: 'Error trying to get JIRA user');
      }
    } catch (e) {
      return BaseResponse(success: false, message: 'Error api call: $e');
    }
  }

  Future<BaseResponse> getResources(String token) async {
    if (token.isEmpty) return BaseResponse(success: false, message: 'Token is Empty');
    try {
      final response = await http.get(jiraApiAuthUrl('oauth/token/accessible-resources'), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        return BaseResponse(success: true, message: 'Login successfully', data: responseBody[0]);
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

  // Future<BaseResponse> searchIssues2() async {
  //   final accessToken = await accessJiraToken;
  //   final userEmail = await email;

  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/jiraIssues').replace(queryParameters: {'access_token': accessToken, 'email': userEmail}));

  //     final Map<String, dynamic> data = json.decode(response.body);

  //     return BaseResponse(success: true, data: data);
  //   } catch (e) {
  //     SnackBar(content: Text('error: $e'));
  //     return BaseResponse(success: false);
  //   }
  // }

  Future<BaseResponse> searchIssues({required String query, int maxResults = 20, List<String>? fields, int startAt = 0}) async {
    final accessToken = await accessJiraToken;
    final account = await accountId;

    final String credentials = '$email:$accessToken';
    final String encodeCredentials = base64Encode(utf8.encode(credentials));

    try {
      Uri uri = Uri.parse('$jiraApiUrl/rest/api/3/search/jql').replace(
        queryParameters: {
          'jql': 'text ~ "NMS" AND issuetype in ("Story", "Bug") AND labels = "Refined"',
          //'maxResults': maxResults.toString(),
          //'startAt': startAt.toString(),
          if (fields != null && fields.isNotEmpty) 'fields': fields.join(','),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Atlassian-Token': 'no-check',
          'X-AAccountId': account,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      final data = json.encode(response.body);

      return BaseResponse(success: response.statusCode == 200, data: data);
    } catch (e) {
      return BaseResponse(success: false, message: 'There was an error: $e');
    }
  }
}
