import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/app_user.dart';

part 'room.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class Room {
  String? name;
  String? id;
  DateTime? dateAdded;
  DateTime? dateDeleted;
  final List<Story> stories;
  final List<VoteEnum> cardsToUse;
  List<AppUser>? currentUsers;
  String userId;

  Room({this.name, this.id, this.dateAdded, this.dateDeleted, required this.stories, required this.cardsToUse, this.currentUsers, required this.userId});

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);

  Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
    'name': instance.name,
    'id': instance.id,
    'dateAdded': instance.dateAdded?.toIso8601String(),
    'dateDeleted': instance.dateDeleted?.toIso8601String(),
    'stories': instance.stories.map((story) => story.toJson()).toList(),
    'cardsToUse': instance.cardsToUse.map((card) => _$VoteEnumEnumMap[card]!),
    'currentUsers': instance.currentUsers?.map((user) => user.toJson()).toList(),
    'userId': instance.userId,
  };
}
