// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AppUser',
      json,
      ($checkedConvert) {
        final val = AppUser(
          id: $checkedConvert('id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String),
          accountId: $checkedConvert('account_id', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          picture: $checkedConvert('picture', (v) => v as String?),
          accountType: $checkedConvert('account_type', (v) => v as String?),
          cloudId: $checkedConvert('cloud_id', (v) => v as String?),
          moderator: $checkedConvert('moderator', (v) => v as bool? ?? false),
          observer: $checkedConvert('observer', (v) => v as bool? ?? false),
        );
        $checkedConvert(
            'joinedRoomDate',
            (v) => val.joinedRoomDate =
                v == null ? null : DateTime.parse(v as String));
        return val;
      },
      fieldKeyMap: const {
        'accountId': 'account_id',
        'accountType': 'account_type',
        'cloudId': 'cloud_id'
      },
    );
