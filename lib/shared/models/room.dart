import 'package:scrum_poker/shared/models/story.dart';

class Room {
  String name;
  final String id;
  final DateTime dateAdded;
  DateTime? dateDeleted;
  final List<Story> stories;

  Room({required this.name, required this.id, required this.dateAdded, this.dateDeleted, required this.stories});
}
