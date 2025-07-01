import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/models/vote_result.dart';

part 'story.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class Story {
  String id;
  String description;
  String? url;
  double? estimate;
  StoryStatus status;
  @JsonKey(includeFromJson: false)
  bool added;
  int? revisedEstimate;
  int order;
  bool currentStory;

  Story({
    required this.id,
    required this.description,
    this.url,
    this.estimate,
    required this.status,
    this.added = false,
    this.revisedEstimate,
    required this.order,
    this.currentStory = false
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);

  Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
    'id': instance.id,
    'description': instance.description,
    if (instance.url case final value?) 'url': value,
    if (instance.estimate case final value?) 'estimate': value,
    'status': _$StoryStatusEnumMap[instance.status],
    if (instance.revisedEstimate case final value?) 'revisedEstimate': value,
    'order': instance.order,
    'currentStory': instance.currentStory
  };


  List<VoteResult>? voteResults(List<Vote> votes) {
    if (status != StoryStatus.voted) return null;
    final ret = <VoteResult>[];
    for (final vote in votes) {
      var voteResult = ret.firstWhereOrNull((e) => e.vote == vote.value);
      if (voteResult == null) {
        voteResult = VoteResult(vote: vote.value, count: 0);
        ret.add(voteResult);
      }

      voteResult.count++;
    }
    return ret;
  }
}
