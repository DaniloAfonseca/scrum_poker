import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scrum_poker/jira_authentication.dart';
import 'package:scrum_poker/shared/helpers/credentials_helper.dart' as credentials_helper;
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/base_response.dart';
import 'package:scrum_poker/shared/models/access_token.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';
import 'package:scrum_poker/shared/models/jira_field.dart';
import 'package:scrum_poker/shared/models/jira_issue_response.dart';
import 'package:scrum_poker/shared/services/base_services.dart';

class JiraServices extends BaseServices {
  //String get jiraApiUrl => 'https://api.atlassian.com/ex/jira/e2969eda-f627-4429-ae2f-be8262224890';

  JiraCredentials? get credentials => JiraCredentialsManager().currentCredentials;

  Future<BaseResponse<AppUser>> getJiraUser(String token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Token is empty');
    }

    try {
      final response = await http.get(jiraApiAuthUrl('me'), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        return BaseResponse<AppUser>(success: true, message: 'Login successfully', data: AppUser.fromJiraJson(responseBody));
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

  Future<BaseResponse<AccessToken>> accessToken(String token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Token is empty');
    }

    final response = await http.post(
      jiraApiAuthUrl('oauth/token'),
      headers: {'Content-Type': 'application/json'},

      body: json.encode({
        "grant_type": "authorization_code",
        "client_id": JiraAuthentication.clientId,
        "client_secret": JiraAuthentication.secret,
        "code": token,
        "redirect_uri": "${Uri.base.origin}/login",
      }),
    );

    return BaseResponse<AccessToken>(success: response.statusCode == 200, data: AccessToken.fromJson(json.decode(response.body)));
  }

  Future<BaseResponse<AccessToken>> refreshToken(String token) async {
    if (token.isEmpty) {
      return BaseResponse(success: false, message: 'Refresh Token is empty');
    }

    final response = await http.post(
      jiraApiAuthUrl('oauth/token'),
      headers: {'Content-Type': 'application/json'},

      body: json.encode({
        "grant_type": "refresh_token",
        "client_id": JiraAuthentication.clientId,
        "client_secret": JiraAuthentication.secret,
        "refresh_token": token,
        "redirect_uri": "${Uri.base.origin}/redirect",
      }),
    );

    return BaseResponse<AccessToken>(success: response.statusCode == 200, data: AccessToken.fromJson(json.decode(response.body)));
  }

  Future<BaseResponse<JiraIssueResponse>> searchIssues({required String query, int maxResults = 20, List<String>? fields, String? nextPageToken}) async {
    final checkCredentialsResponse = await checkCredentials();
    if (checkCredentialsResponse != null) return BaseResponse(success: false, message: checkCredentialsResponse);

    try {
      final headers = getHeaders(credentials!.accessToken!, credentials!.accountId!);

      if (headers == null) return BaseResponse(success: false, message: 'There is an error in headers');

      Uri uri = Uri.parse('${jiraApiUrl(credentials!.cloudId!, 'rest/api/3')}/search/jql').replace(
        queryParameters: {'jql': query, 'maxResults': maxResults.toString(), 'nextPageToken': nextPageToken, if (fields != null && fields.isNotEmpty) 'fields': fields.join(',')},
      );
      final response = await http.get(uri, headers: headers);

      final data = json.decode(response.body);

      return BaseResponse<JiraIssueResponse>(success: response.statusCode == 200, data: JiraIssueResponse.fromJson(data));
    } catch (e) {
      return BaseResponse(success: false, message: 'There was an error: $e');
    }
  }

  Future<BaseResponse<List<JiraField>>> getAllFields() async {
    final checkCredentialsResponse = await checkCredentials();
    if (credentials != null) return BaseResponse(success: false, message: checkCredentialsResponse);

    try {
      final headers = getHeaders(credentials!.accessToken!, credentials!.accountId!);

      if (headers == null) return BaseResponse<List<JiraField>>(success: false, message: 'There is an error in headers');

      Uri uri = Uri.parse('${jiraApiUrl(credentials!.cloudId!, 'rest/api/3')}/field');
      final response = await http.get(uri, headers: headers);

      final data = json.decode(response.body) as List;

      return BaseResponse<List<JiraField>>(success: response.statusCode == 200, data: data.map((t) => JiraField.fromJson(t)).toList());
    } catch (e) {
      return BaseResponse<List<JiraField>>(success: false, message: 'There was an error: $e');
    }
  }

  Future<String?> checkCredentials() async {
    if (credentials == null) return 'You don\'t have access token.';

    if (DateTime.parse(credentials!.expireDate!).isBefore(DateTime.now())) {
      final response = await refreshToken(credentials!.refreshToken!);
      if (!response.success) {
        return 'There was an error trying refresh token';
      }
      await credentials_helper.getCredentials(response.data!);
    }
    return null;
  }

  Map<String, String>? getHeaders(String token, String accountId) => {
    'Authorization': 'Bearer $token',
    'X-Atlassian-Token': 'no-check',
    'X-AAccountId': accountId,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
