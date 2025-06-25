import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/vote.dart';

part 'story.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class Story {
  String id;
  String description;
  String? url;
  int? estimate;
  StoryStatus status;
  final List<Vote> votes;
  @JsonKey(includeFromJson: false)
  bool added;
  int? revisedEstimate;
  int order;

  Story({
    required this.id,
    required this.description,
    this.url,
    this.estimate,
    required this.status,
    required this.votes,
    this.added = false,
    this.revisedEstimate,
    required this.order,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);

  Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
    if (instance.url case final value?) 'url': value,
    if (instance.estimate case final value?) 'estimate': value,
    'status': _$StoryStatusEnumMap[instance.status],
    'votes': votes.map((vote) => vote.toJson()).toList(),
    if (instance.revisedEstimate case final value?) 'revisedEstimate': value,
    'order': instance.order,
  };
}
