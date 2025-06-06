import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/vote.dart';

class Story {
  String description;
  String? url;
  int? vote;
  StoryStatusEnum status;
  final List<Vote> votes;
  bool added;

  Story({required this.description, this.url, this.vote, required this.status, required this.votes, this.added = false});
}
