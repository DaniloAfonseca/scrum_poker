import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';

part 'user_room.g.dart';

@JsonSerializable(includeIfNull: false)
class UserRoom {
  final String userId;
  final String roomId;
  String name;
  DateTime? dateAdded;
  DateTime? dateDeleted;
  RoomStatus status;
  int? activeStories;
  int? skippedStories;
  int? completedStories;
  int? allStories;

  UserRoom({
    required this.userId,
    required this.roomId,
    required this.name,
    this.dateAdded,
    this.dateDeleted,
    required this.status,
    this.activeStories,
    this.completedStories,
    this.skippedStories,
  });

  factory UserRoom.fromJson(Map<String, dynamic> json) => _$UserRoomFromJson(json);
  Map<String, dynamic> toJson() => _$UserRoomToJson(this);

  factory UserRoom.fromRoom(Room room) {
    return UserRoom(userId: room.userId, roomId: room.id, name: room.name!, status: room.status, dateAdded: room.dateAdded, dateDeleted: room.dateDeleted);
  }
}
