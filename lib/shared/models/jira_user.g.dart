// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jira_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JiraUser _$JiraUserFromJson(Map<String, dynamic> json) => $checkedCreate(
  'JiraUser',
  json,
  ($checkedConvert) {
    final val = JiraUser(
      accountId: $checkedConvert('account_id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String?),
      picture: $checkedConvert('picture', (v) => v as String?),
      accountType: $checkedConvert('account_type', (v) => v as String?),
      cloudId: $checkedConvert('cloud_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'accountId': 'account_id',
    'accountType': 'account_type',
    'cloudId': 'cloud_id',
  },
);

Map<String, dynamic> _$JiraUserToJson(JiraUser instance) => <String, dynamic>{
  'account_id': instance.accountId,
  'email': instance.email,
  'name': instance.name,
  'picture': instance.picture,
  'account_type': instance.accountType,
  'cloud_id': instance.cloudId,
};
