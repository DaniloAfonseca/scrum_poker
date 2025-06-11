// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('User', json, ($checkedConvert) {
      final val = User(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        rooms: $checkedConvert(
          'rooms',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => Room.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
      );
      return val;
    });
