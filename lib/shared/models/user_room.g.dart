// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRoom _$UserRoomFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserRoom', json, ($checkedConvert) {
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
          (v) => $enumDecode(_$StatusEnumEnumMap, v),
        ),
      );
      return val;
    });

const _$StatusEnumEnumMap = {
  StatusEnum.notStarted: 'notStarted',
  StatusEnum.started: 'started',
  StatusEnum.skipped: 'skipped',
  StatusEnum.ended: 'ended',
};
