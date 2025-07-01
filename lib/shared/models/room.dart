import 'package:scrum_poker/shared/models/enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class Room {
  String? name;
  String? id;
  DateTime? dateAdded;
  DateTime? dateDeleted;
  //final List<Story> stories;
  final List<VoteEnum> cardsToUse;
  //List<AppUser>? currentUsers;
  String userId;
  RoomStatus status;
  //Story? get currentStory => stories.firstWhereOrNull((t) => t.currentStory);

  Room({
    this.name,
    this.id,
    this.dateAdded,
    this.dateDeleted,
    //required this.stories,
    required this.cardsToUse,
    //this.currentUsers,
    required this.userId,
    required this.status,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);

  Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
    'name': instance.name,
    'id': instance.id,
    if (instance.dateAdded?.toIso8601String() case final value?) 'dateAdded': value,
    if (instance.dateDeleted?.toIso8601String() case final value?) 'dateDeleted': value,
    //'stories': instance.stories.map((story) => story.toJson()).toList(),
    'cardsToUse': instance.cardsToUse.map((card) => _$VoteEnumEnumMap[card]!),
    //if (instance.currentUsers?.map((user) => user.toJson()).toList() case final value?) 'currentUsers': value,
    'userId': instance.userId,
    'status': _$RoomStatusEnumMap[instance.status],
    //if (instance.currentStory?.toJson() case final value?) 'currentStory': value,
  };
}
