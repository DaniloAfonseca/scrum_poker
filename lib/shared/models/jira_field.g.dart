// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jira_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JiraField _$JiraFieldFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JiraField', json, ($checkedConvert) {
      final val = JiraField(
        id: $checkedConvert('id', (v) => v as String),
        key: $checkedConvert('key', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        custom: $checkedConvert('custom', (v) => v as bool),
        orderable: $checkedConvert('orderable', (v) => v as bool),
        navigable: $checkedConvert('navigable', (v) => v as bool),
        searchable: $checkedConvert('searchable', (v) => v as bool),
        clauseNames: $checkedConvert(
          'clauseNames',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        schema: $checkedConvert(
          'schema',
          (v) => v == null
              ? null
              : JiraFieldSchema.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

JiraFieldSchema _$JiraFieldSchemaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JiraFieldSchema', json, ($checkedConvert) {
      final val = JiraFieldSchema(
        type: $checkedConvert('type', (v) => v as String),
        system: $checkedConvert('system', (v) => v as String?),
        items: $checkedConvert('items', (v) => v as String?),
        custom: $checkedConvert('custom', (v) => v as String?),
        customId: $checkedConvert('customId', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

JiraFieldScope _$JiraFieldScopeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JiraFieldScope', json, ($checkedConvert) {
      final val = JiraFieldScope(
        type: $checkedConvert('type', (v) => v as String),
        project: $checkedConvert(
          'project',
          (v) => v == null
              ? null
              : JiraFieldScopeProject.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

JiraFieldScopeProject _$JiraFieldScopeProjectFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('JiraFieldScopeProject', json, ($checkedConvert) {
  final val = JiraFieldScopeProject(
    id: $checkedConvert('id', (v) => v as String),
  );
  return val;
});
