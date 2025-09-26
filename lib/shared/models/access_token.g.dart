// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessToken _$AccessTokenFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AccessToken',
  json,
  ($checkedConvert) {
    final val = AccessToken(
      token: $checkedConvert('access_token', (v) => v as String?),
      refreshToken: $checkedConvert('refresh_token', (v) => v as String?),
      expires: $checkedConvert('expires_in', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'token': 'access_token',
    'refreshToken': 'refresh_token',
    'expires': 'expires_in',
  },
);
