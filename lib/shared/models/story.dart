import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/vote.dart';

part 'story.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class Story {
  String description;
  String? url;
  int? vote;
  StatusEnum status;
  final List<Vote> votes;
  @JsonKey(includeFromJson: false)
  bool added;

  Story({required this.description, this.url, this.vote, required this.status, required this.votes, this.added = false});

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);

  Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
    'description': instance.description,
    'url': instance.url,
    'vote': instance.vote,
    'status': _$StatusEnumEnumMap[instance.status],
    'votes': votes.map((vote) => vote.toJson()).toList()
  };
}
