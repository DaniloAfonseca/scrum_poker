import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/room.dart';

part 'app_user.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class AppUser {
  final String? id;
  final String name;
  final List<Room>? rooms;
  final bool moderator;
  final bool observer;

  AppUser({this.id, required this.name, this.rooms, this.moderator = false, this.observer = false});

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'rooms': instance.rooms?.map((room) => room.toJson()).toList(),
    'moderator': instance.moderator,
    'observer': instance.observer
  };

  factory AppUser.fromAppUser(AppUser user, bool moderator) {
    return AppUser(name: user.name, moderator: moderator);
  }
}
