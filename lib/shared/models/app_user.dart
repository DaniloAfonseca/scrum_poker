import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/room.dart';

part 'app_user.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class AppUser {
  @JsonKey(name: 'account_id')
  final String? accountId;
  final String? email;
  final String? id;
  final String name;
  final String? picture;
  final List<Room>? rooms;
  final bool moderator;
  final bool observer;
  @JsonKey(name: 'account_type')
  final String? accountType;
  @JsonKey(name: 'cloud_id')
  final String? cloudId;

  AppUser({this.accountId, this.id, required this.name, this.email, this.picture, this.accountType, this.cloudId, this.rooms, this.moderator = false, this.observer = false});

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
    'accountId': instance.accountId,
    'email': instance.email,
    'id': instance.id,
    'name': instance.name,
    'picture': instance.picture,
    'account_type': instance.accountType,
    'cloud_id': instance.cloudId,
    'rooms': instance.rooms?.map((room) => room.toJson()).toList(),
    'moderator': instance.moderator,
    'observer': instance.observer,
  };

  factory AppUser.fromAppUser(AppUser user, bool moderator) {
    return AppUser(name: user.name, moderator: moderator);
  }
}
