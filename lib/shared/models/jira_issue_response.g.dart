// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jira_issue_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JiraIssueResponse _$JiraIssueResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'JiraIssueResponse',
      json,
      ($checkedConvert) {
        final val = JiraIssueResponse(
          isLast: $checkedConvert('isLast', (v) => v as bool?),
          issues: $checkedConvert(
              'issues',
              (v) => (v as List<dynamic>)
                  .map((e) => JiraIssue.fromJson(e as Map<String, dynamic>))
                  .toList()),
          nextPageToken: $checkedConvert('nextPageToken', (v) => v as String?),
        );
        return val;
      },
    );

JiraIssue _$JiraIssueFromJson(Map<String, dynamic> json) => $checkedCreate(
      'JiraIssue',
      json,
      ($checkedConvert) {
        final val = JiraIssue(
          fields: $checkedConvert(
              'fields',
              (v) => v == null
                  ? null
                  : JiraFields.fromJson(v as Map<String, dynamic>)),
          id: $checkedConvert('id', (v) => v as String),
          key: $checkedConvert('key', (v) => v as String),
          self: $checkedConvert('self', (v) => v as String),
          storyPoints:
              $checkedConvert('storyPoints', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

JiraFields _$JiraFieldsFromJson(Map<String, dynamic> json) => $checkedCreate(
      'JiraFields',
      json,
      ($checkedConvert) {
        final val = JiraFields(
          issueType: $checkedConvert(
              'issuetype',
              (v) => v == null
                  ? null
                  : JiraIssueType.fromJson(v as Map<String, dynamic>)),
          statusCategory: $checkedConvert(
              'statusCategory',
              (v) => v == null
                  ? null
                  : JiraStatusCategory.fromJson(v as Map<String, dynamic>)),
          summary: $checkedConvert('summary', (v) => v as String?),
          votes: $checkedConvert(
              'votes',
              (v) => v == null
                  ? null
                  : JiraVotes.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'issueType': 'issuetype'},
    );

JiraIssueType _$JiraIssueTypeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'JiraIssueType',
      json,
      ($checkedConvert) {
        final val = JiraIssueType(
          name: $checkedConvert('name', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
        );
        return val;
      },
    );

JiraStatusCategory _$JiraStatusCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'JiraStatusCategory',
      json,
      ($checkedConvert) {
        final val = JiraStatusCategory(
          name: $checkedConvert('name', (v) => v as String),
          id: $checkedConvert('id', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

JiraVotes _$JiraVotesFromJson(Map<String, dynamic> json) => $checkedCreate(
      'JiraVotes',
      json,
      ($checkedConvert) {
        final val = JiraVotes(
          hasVoted: $checkedConvert('hasVoted', (v) => v as bool),
          self: $checkedConvert('self', (v) => v as String),
          vote: $checkedConvert('vote', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );
