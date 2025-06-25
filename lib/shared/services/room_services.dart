import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';

Future<void> addUserToStory(AppUser? appUser, Room room) async {
  if (appUser == null) {
    return;
  }

  // add user to room
  if (room.currentUsers?.any((t) => t.id == appUser.id) != true) {
    room.currentUsers ??= [];
    room.currentUsers!.add(appUser);
    final roomMap = room.toJson();
    await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(roomMap);
  }
}

Future<void> removeUser(AppUser appUser, Room room) async {
  room.currentUsers?.removeWhere((t) => t.id == appUser.id);
  await saveRoom(room);
}

Future<void> saveRoom(Room room) async {
  final json = room.toJson();
  await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(json);
}

Future<void> storyStart(Room room) async {
  await saveRoom(room);
}

Future<void> moveStoryUp(Room room, int index, Story story) async {
  final previousStory = room.stories[index - 1];
  room.stories[index - 1] = story;
  room.stories[index] = previousStory;
  _setStoriesOrder(room);
  await saveRoom(room);
}

Future<void> moveStoryDown(Room room, int index, Story story) async {
  final nextStory = room.stories[index + 1];
  room.stories[index + 1] = story;
  room.stories[index] = nextStory;
  _setStoriesOrder(room);
  await saveRoom(room);
}

void _setStoriesOrder(Room room) {
  for (var i = 0; i < room.stories.length; i++) {
    room.stories[i].order = i;
  }
}

Future<void> removeStory(Room room, Story story) async {
  room.stories.remove(story);
  for (var i = 0; i < room.stories.length; i++) {
    room.stories[i].order = i;
  }
  room.currentStory = null;
  await saveRoom(room);
}

Future<void> skipStory(Room room, Story story) async {
  story.votes.clear();
  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.skipped;
  room.currentStory = null;
  await saveRoom(room);
}

Future<void> clearStoryVotes(Room room, Story story) async {
  story.votes.clear();
  story.estimate = null;
  story.revisedEstimate = null;
  await saveRoom(room);
}

Future<void> moveStoryToActive(Room room, Story story) async {
  story.status = StoryStatus.notStarted;
  room.currentStory = null;
  await saveRoom(room);
}

Future<void> swapStories(Room room, Story story1, Story story2) async {
  final index1 = room.stories.indexOf(story1);
  final index2 = room.stories.indexOf(story2);
  room.stories[index1] = story2;
  room.stories[index2] = story1;
  _setStoriesOrder(room);
  room.currentStory = null;
  await saveRoom(room);
}
