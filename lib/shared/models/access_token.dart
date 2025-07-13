import 'package:json_annotation/json_annotation.dart';

part 'access_token.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class AccessToken {
  @JsonKey(name: 'access_token')
  String? token;
  @JsonKey(name: 'refresh_token')
  String? refreshToken;
  @JsonKey(name: 'expires_in')
  int? expires;

  AccessToken({this.token, this.refreshToken, this.expires});

  factory AccessToken.fromJson(Map<String, dynamic> json) => _$AccessTokenFromJson(json);
}
