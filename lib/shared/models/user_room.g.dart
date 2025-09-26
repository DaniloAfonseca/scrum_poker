// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRoom _$UserRoomFromJson(Map<String, dynamic> json) => $checkedCreate(
  'UserRoom',
  json,
  ($checkedConvert) {
    final val = UserRoom(
      userId: $checkedConvert('userId', (v) => v as String),
      roomId: $checkedConvert('roomId', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      dateAdded: $checkedConvert(
        'dateAdded',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      dateDeleted: $checkedConvert(
        'dateDeleted',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$RoomStatusEnumMap, v),
      ),
      activeStories: $checkedConvert(
        'activeStories',
        (v) => (v as num?)?.toInt(),
      ),
      completedStories: $checkedConvert(
        'completedStories',
        (v) => (v as num?)?.toInt(),
      ),
      skippedStories: $checkedConvert(
        'skippedStories',
        (v) => (v as num?)?.toInt(),
      ),
      isDeleted: $checkedConvert('isDeleted', (v) => v as bool? ?? false),
    );
    $checkedConvert('allStories', (v) => val.allStories = (v as num?)?.toInt());
    return val;
  },
);

Map<String, dynamic> _$UserRoomToJson(UserRoom instance) => <String, dynamic>{
  'userId': instance.userId,
  'roomId': instance.roomId,
  'name': instance.name,
  if (instance.dateAdded?.toIso8601String() case final value?)
    'dateAdded': value,
  if (instance.dateDeleted?.toIso8601String() case final value?)
    'dateDeleted': value,
  'status': _$RoomStatusEnumMap[instance.status]!,
  if (instance.activeStories case final value?) 'activeStories': value,
  if (instance.skippedStories case final value?) 'skippedStories': value,
  if (instance.completedStories case final value?) 'completedStories': value,
  if (instance.allStories case final value?) 'allStories': value,
  'isDeleted': instance.isDeleted,
};

const _$RoomStatusEnumMap = {
  RoomStatus.notStarted: 'notStarted',
  RoomStatus.started: 'started',
  RoomStatus.ended: 'ended',
};
