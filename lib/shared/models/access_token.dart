import 'package:json_annotation/json_annotation.dart';

part 'access_token.g.dart';

/// Jira access token
@JsonSerializable(createToJson: false, includeIfNull: false)
class AccessToken {
  /// Jira access token
  @JsonKey(name: 'access_token')
  String? token;
  /// Jira refresh token, used to get new access token and can only be used once
  @JsonKey(name: 'refresh_token')
  String? refreshToken;
  /// Number of seconds when the token will be expired
  @JsonKey(name: 'expires_in')
  int? expires;

  /// Access token constructor
  /// 
  /// [token] optional, Jira access token
  /// [refreshToken] optional, Jira refresh token
  /// [expires] optional, number of seconds when the token will be expired
  AccessToken({this.token, this.refreshToken, this.expires});

  /// Factory used to create the access token class from json
  /// 
  /// [json] json value to create a access toke class
  factory AccessToken.fromJson(Map<String, dynamic> json) => _$AccessTokenFromJson(json);
}
