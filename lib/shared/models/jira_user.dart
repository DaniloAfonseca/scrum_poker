import 'package:json_annotation/json_annotation.dart';

part 'jira_user.g.dart';

@JsonSerializable()
class JiraUser {
  @JsonKey(name: 'account_id')
  final String accountId;
  final String? email;
  final String? name;
  final String? picture;
  @JsonKey(name: 'account_type')
  final String? accountType;
  @JsonKey(name: 'cloud_id')
  final String? cloudId;

  JiraUser({required this.accountId, this.email, this.name, this.picture, this.accountType, this.cloudId});

  factory JiraUser.fromJson(Map<String, dynamic> json) => _$JiraUserFromJson(json);
  Map<String, dynamic> toJson() => _$JiraUserToJson(this);
}
