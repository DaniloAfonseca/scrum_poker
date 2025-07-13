import 'package:json_annotation/json_annotation.dart';

part 'jira_field.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraField {
  String id;
  String key;
  String name;
  bool custom;
  bool orderable;
  bool navigable;
  bool searchable;
  List<String>? clauseNames;
  JiraFieldSchema? schema;

  JiraField({
    required this.id,
    required this.key,
    required this.name,
    required this.custom,
    required this.orderable,
    required this.navigable,
    required this.searchable,
    this.clauseNames,
    this.schema,
  });

  factory JiraField.fromJson(Map<String, dynamic> json) => _$JiraFieldFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraFieldSchema {
  String type;
  String? system;
  String? items;
  String? custom;
  int? customId;

  JiraFieldSchema({required this.type, this.system, this.items, this.custom, this.customId});

  factory JiraFieldSchema.fromJson(Map<String, dynamic> json) => _$JiraFieldSchemaFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraFieldScope {
  String type;
  JiraFieldScopeProject? project;

  JiraFieldScope({required this.type, this.project});

  factory JiraFieldScope.fromJson(Map<String, dynamic> json) => _$JiraFieldScopeFromJson(json);
}

@JsonSerializable(createToJson: false, includeIfNull: false)
class JiraFieldScopeProject {
  String id;

  JiraFieldScopeProject({required this.id});

  factory JiraFieldScopeProject.fromJson(Map<String, dynamic> json) => _$JiraFieldScopeProjectFromJson(json);
}
