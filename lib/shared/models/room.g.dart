// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Room', json, ($checkedConvert) {
      final val = Room(
        name: $checkedConvert('name', (v) => v as String?),
        id: $checkedConvert('id', (v) => v as String?),
        dateAdded: $checkedConvert(
          'dateAdded',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        dateDeleted: $checkedConvert(
          'dateDeleted',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        stories: $checkedConvert(
          'stories',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => Story.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
      );
      return val;
    });
