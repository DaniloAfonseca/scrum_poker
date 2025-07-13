import 'package:json_annotation/json_annotation.dart';

part 'jira_issue_response.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraIssueResponse {
  bool? isLast;
  List<JiraIssue> issues;
  String? nextPageToken;

  JiraIssueResponse({required this.isLast, required this.issues, this.nextPageToken});

  factory JiraIssueResponse.fromJson(Map<String, dynamic> json) => _$JiraIssueResponseFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraIssue {
  JiraFields? fields;
  String id;
  String key;
  String self;
  int? storyPoints;

  JiraIssue({this.fields, required this.id, required this.key, required this.self, this.storyPoints});

  factory JiraIssue.fromJson(Map<String, dynamic> json) => _$JiraIssueFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraFields {
  @JsonKey(name: 'issuetype')
  JiraIssueType? issueType;
  JiraStatusCategory? statusCategory;
  String? summary;
  JiraVotes? votes;

  JiraFields({this.issueType, this.statusCategory, this.summary, this.votes});

  factory JiraFields.fromJson(Map<String, dynamic> json) => _$JiraFieldsFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraIssueType {
  String name;
  String id;

  JiraIssueType({required this.name, required this.id});

  factory JiraIssueType.fromJson(Map<String, dynamic> json) => _$JiraIssueTypeFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraStatusCategory {
  String name;
  int id;

  JiraStatusCategory({required this.name, required this.id});

  factory JiraStatusCategory.fromJson(Map<String, dynamic> json) => _$JiraStatusCategoryFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraVotes {
  bool hasVoted;
  String self;
  int? vote;

  JiraVotes({required this.hasVoted, required this.self, required this.vote});

  factory JiraVotes.fromJson(Map<String, dynamic> json) => _$JiraVotesFromJson(json);
}
