// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppUser', json, ($checkedConvert) {
      final val = AppUser(
        id: $checkedConvert('id', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
        rooms: $checkedConvert(
          'rooms',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Room.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
        moderator: $checkedConvert('moderator', (v) => v as bool? ?? false),
        observer: $checkedConvert('observer', (v) => v as bool? ?? false),
      );
      return val;
    });
