import 'package:scrum_poker/shared/models/story.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

@JsonSerializable(createToJson: false)
class Room {
  String? name;
  String? id;
  DateTime? dateAdded;
  DateTime? dateDeleted;
  final List<Story> stories;

  Room({this.name, this.id, this.dateAdded, this.dateDeleted, required this.stories});

  factory Room.fromJson(Map<String, dynamic> json) =>  _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);

  Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
    'name': instance.name,
    'id': instance.id,
    'dateAdded': instance.dateAdded?.toIso8601String(),
    'dateDeleted': instance.dateDeleted?.toIso8601String(),
    'stories': stories.map((story) => story.toJson()).toList(),
  };
}
