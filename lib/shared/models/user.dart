import 'package:scrum_poker/shared/models/room.dart';

class User {
  final String id;
  final String name;
  final List<Room> rooms;

  User({required this.id, required this.name, required this.rooms});

  Map<String, dynamic> toJson() => _$UserToJson(this);
  Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{'id': instance.id, 'name': instance.name, 'rooms': rooms.map((room) => room.toJson()).toList()};
}
