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
  await FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('currentUsers').doc(appUser.id).set(appUser.toJson(), SetOptions(merge: true));
}

Future<void> removeUser(AppUser appUser, Room room) async {
  await FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('currentUsers').doc(appUser.id).delete();
}

Future<void> saveRoom(Room room, {String? userId}) async {
  final json = room.toJson();
  await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(json);

  if (userId != null) {
    final dbRoom = await FirebaseFirestore.instance.collection('users').doc(userId).collection('rooms').doc(room.id).snapshots().first;
    final userRoom = Room.fromJson(dbRoom.data()!);
    room.status = userRoom.status;
    final roomMap = room.toJson();
    await FirebaseFirestore.instance.collection('users').doc(userId).collection('rooms').doc(room.id).update(roomMap);
  }
}

Future<void> storyStart(Room room, Story story, String userId) async {
  final roomStatus = room.status;
  story.status = StoryStatus.started;
  _setRoomStatus(room);
  await saveRoom(room, userId: roomStatus != room.status ? userId : null);
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

Future<void> removeStory(Room room, Story story, String userId) async {
  room.stories.remove(story);
  for (var i = 0; i < room.stories.length; i++) {
    room.stories[i].order = i;
  }
  story.currentStory = false;
  final roomStatus = room.status;
  _setRoomStatus(room);

  await saveRoom(room, userId: roomStatus != room.status ? userId : null);
}

Future<void> skipStory(Room room, Story story, String userId) async {
  story.votes.clear();
  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.skipped;
  story.currentStory = false;
  final roomStatus = room.status;
  _setRoomStatus(room);

  await saveRoom(room, userId: roomStatus != room.status ? userId : null);
}

Future<void> flipCards(Room room, Story story, String userId) async {
  final validVotes = story.votes.where((e) => e.value.value != null);
  final validVotesSum = validVotes.map((e) => e.value.value).reduce((e, t) => e! + t!)!;
  story.estimate = double.parse((validVotesSum / validVotes.length).toStringAsFixed(2));
  story.revisedEstimate = null;
  story.status = StoryStatus.voted;
  final roomStatus = room.status;
  _setRoomStatus(room);

  await saveRoom(room, userId: roomStatus != room.status ? userId : null);
}

Future<void> clearStoryVotes(Room room, Story story) async {
  if (story.status != StoryStatus.started) {
    return;
  }
  story.votes.clear();
  story.estimate = null;
  story.revisedEstimate = null;
  await saveRoom(room);
}

Future<void> moveStoryToActive(Room room, Story story, String userId) async {
  story.status = StoryStatus.notStarted;
  story.currentStory = false;
  final roomStatus = room.status;
  _setRoomStatus(room);

  await saveRoom(room, userId: roomStatus != room.status ? userId : null);
}

Future<void> nextStory(Room room, Story story) async {
  story.status = StoryStatus.ended;
  story.currentStory = false;
  _setRoomStatus(room);
  await saveRoom(room);
}

Future<void> swapStories(Room room, Story story1, Story story2) async {
  final index1 = room.stories.indexOf(story1);
  final index2 = room.stories.indexOf(story2);
  room.stories[index1] = story2;
  room.stories[index2] = story1;
  _setStoriesOrder(room);
  story1.currentStory = false;
  story2.currentStory = false;
  await saveRoom(room);
}

void _setRoomStatus(Room room) {
  final anyStarted = room.stories.any((t) => [StoryStatus.started, StoryStatus.skipped, StoryStatus.voted, StoryStatus.ended].contains(t.status));
  final allEnded = room.stories.every((t) => [StoryStatus.ended, StoryStatus.skipped].contains(t.status));

  if (allEnded) {
    room.status = RoomStatus.ended;
  } else if (anyStarted) {
    room.status = RoomStatus.started;
  } else {
    room.status = RoomStatus.notStarted;
  }
}
