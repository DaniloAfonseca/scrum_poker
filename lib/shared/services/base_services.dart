import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scrum_poker/shared/models/base_response.dart';

class BaseServices {
  final String baseUrl = 'https://jiraauth-fvxqqvi45a-uc.a.run.app';

  Future<Map<String, String>> _getHeaders({required String token}) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<BaseResponse<T>> getRequest<T>(String endpoint, T Function(Object? json) fromJsonT, {String token = ''}) async {
    final headers = await _getHeaders(token: token);
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);

    if (response.statusCode == 200) {
      return _handleResponse(response, fromJsonT);
    } else {
      return BaseResponse<T>(success: false, message: 'Error: ${response.statusCode}', data: null);
    }
  }

  BaseResponse<T> _handleResponse<T>(http.Response response, T Function(Object? json) fromJsonT) {
    if (response.statusCode == 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return BaseResponse<T>.fromJson(json, fromJsonT);
    } else {
      return BaseResponse<T>(success: false, message: 'Error: ${response.statusCode}, ${response.reasonPhrase}', data: null);
    }
  }
}
