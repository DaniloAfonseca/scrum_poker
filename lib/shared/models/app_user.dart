import 'package:firebase_auth/firebase_auth.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class AppUser {
  @JsonKey(name: 'account_id')
  final String? accountId;
  final String? email;
  final String id;
  final String name;
  bool moderator;
  bool observer;
  DateTime? joinedRoomDate;
  final String? picture;
  @JsonKey(name: 'account_type')
  final String? accountType;
  @JsonKey(name: 'cloud_id')
  final String? cloudId;
  String? roomId;

  AppUser({required this.id, required this.name, this.accountId, this.email, this.picture, this.accountType, this.cloudId, this.moderator = false, this.observer = false, this.roomId});

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
    if (instance.accountId case final value?) 'accountId': value,
    if (instance.email case final value?) 'email': value,
    if (instance.id case final value) 'id': value,
    'name': instance.name,
    'moderator': instance.moderator,
    'observer': instance.observer,
    if (instance.picture case final value?) 'picture': value,
    if (instance.accountType case final value?) 'account_type': value,
    if (instance.cloudId case final value?) 'cloud_id': value,
    if (instance.roomId case final value?) 'roomId': value,
  };

  factory AppUser.fromAppUser(AppUser user, bool moderator, String roomId) {
    return AppUser(id: user.id, name: user.name, moderator: moderator, roomId: roomId);
  }

  factory AppUser.fromUser(User user, String roomId) {
    return AppUser(name: user.displayName ?? user.uid, id: user.uid, moderator: true, roomId: roomId);
  }
}
