import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';

part 'user_room.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class UserRoom {
  final String userId;
  final String roomId;
  String name;
  DateTime? dateAdded;
  DateTime? dateDeleted;
  RoomStatus status;

  UserRoom({required this.userId, required this.roomId, required this.name, this.dateAdded, this.dateDeleted, required this.status});

  factory UserRoom.fromJson(Map<String, dynamic> json) => _$UserRoomFromJson(json);
  Map<String, dynamic> toJson() => _$UserRoomToJson(this);

  Map<String, dynamic> _$UserRoomToJson(UserRoom instance) => <String, dynamic>{
    'userId': instance.userId,
    'roomId': instance.roomId,
    'name': instance.name,
    if (instance.dateAdded?.toIso8601String() case final value?) 'dateAdded': value,
    if (instance.dateDeleted?.toIso8601String() case final value?) 'dateDeleted': value,
    'status': _$RoomStatusEnumMap[instance.status],
  };

  factory UserRoom.fromRoom(Room room) {
    return UserRoom(userId: room.userId, roomId: room.id, name: room.name!, status: room.status, dateAdded: room.dateAdded, dateDeleted: room.dateDeleted);
  }
}
