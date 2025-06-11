import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/room.dart';

part 'user.g.dart';

@JsonSerializable(createToJson: false)
class User {
  final String id;
  final String name;
  final List<Room> rooms;

  User({required this.id, required this.name, required this.rooms});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{'id': instance.id, 'name': instance.name, 'rooms': instance.rooms.map((room) => room.toJson()).toList()};
}
