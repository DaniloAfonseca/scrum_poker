import 'package:firebase_auth/firebase_auth.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class AppUser {
  final String? id;
  final String name;
  bool moderator;
  bool observer;

  AppUser({this.id, required this.name, this.moderator = false, this.observer = false});

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'moderator': instance.moderator,
    'observer': instance.observer
  };

  factory AppUser.fromAppUser(AppUser user, bool moderator) {
    return AppUser(name: user.name, moderator: moderator);
  }

  factory AppUser.fromUser(User user) {
    return AppUser(name: user.displayName ?? user.uid, id: user.uid, moderator: true);
  }

  
}
