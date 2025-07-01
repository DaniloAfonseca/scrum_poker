import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';

// room
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

Future<void> updateRoomStatus(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId) async {
  final newRoomStatus = getRoomStatus(stories);
  if (newRoomStatus != roomStatus) {
    await updateRoom(roomId, userId, {'status': roomStatus.toString()});
  }
}

Future<void> updateRoom(String roomId, String userId, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('rooms').doc(roomId);

  await docRef.update(data);
}

RoomStatus getRoomStatus(List<Story> stories) {
  final anyStarted = stories.any((t) => [StoryStatus.started, StoryStatus.skipped, StoryStatus.voted, StoryStatus.ended].contains(t.status));
  final allEnded = stories.every((t) => [StoryStatus.ended, StoryStatus.skipped].contains(t.status));

  if (allEnded) {
    return RoomStatus.ended;
  } else if (anyStarted) {
    return RoomStatus.started;
  } else {
    return RoomStatus.notStarted;
  }
}

// current users
Future<void> updateCurrentUser(String roomId, String userId, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('currentUsers').doc(userId);
  await docRef.update(data);
}

// story
Future<void> addUserToStory(AppUser? appUser, String roomId) async {
  if (appUser == null) {
    return;
  }

  // add user to room
  await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('currentUsers').doc(appUser.id).set(appUser.toJson(), SetOptions(merge: true));
}

Future<void> removeUser(String roomId, String userId) async {
  await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('currentUsers').doc(userId).delete();
}

Future<void> updateStory(String roomId, String storyId, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(storyId);

  await docRef.update(data);
}

void setCurrentStory(String roomId, List<Story> stories) {
  if (stories.any((t) => t.currentStory)) return;
  stories.sort((a, b) => a.order.compareTo(b.order));
  final activeStories = stories.where((t) => [StoryStatus.notStarted, StoryStatus.started].contains(t.status)).toList();
  for (var i = 0; i < activeStories.length; i++) {
    final story = activeStories[i];
    story.currentStory = i == 0;

    updateStory(roomId, story.id, {'currentStory': story.currentStory});
  }
}

Future<void> storyStart(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId) async {
  story.status = StoryStatus.started;

  await updateStory(roomId, story.id, {'status': story.status.toString()});
  await updateRoomStatus(roomId, roomStatus, stories, story, userId);
}

Future<void> moveStoryUp(String roomId, List<Story> stories, int index, Story story) async {
  final previousStory = stories[index - 1];
  stories[index - 1] = story;
  stories[index] = previousStory;
  _setStoriesOrder(stories);

  await updateStory(roomId, story.id, {'order': story.order});
  await updateStory(roomId, previousStory.id, {'order': previousStory.order});
}

Future<void> updateStoryStatusAndCurrentStory_(String roomId, Story story) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(story.id);
  await docRef.update({'currentStory': false, 'status': story.status.toString()});
}

Future<void> updateStoryOrderAndCurrentStory_(String roomId, Story story) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(story.id);
  await docRef.update({'currentStory': false, 'order': story.order});
}

Future<void> moveStoryDown(String roomId, List<Story> stories, int index, Story story) async {
  final nextStory = stories[index + 1];
  stories[index + 1] = story;
  stories[index] = nextStory;
  _setStoriesOrder(stories);

  await updateStory(roomId, story.id, {'order': story.order});
  await updateStory(roomId, nextStory.id, {'order': nextStory.order});
}

void _setStoriesOrder(List<Story> stories) {
  for (var i = 0; i < stories.length; i++) {
    stories[i].order = i;
  }
}

Future<void> removeStory(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId) async {
  await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(story.id).delete();
  story.currentStory = false;
  stories.remove(story);

  for (var i = 0; i < stories.length; i++) {
    final story = stories[i];
    if (stories[i].order != i) {
      stories[i].order = i;
      await updateStory(roomId, story.id, {'order': story.order});
    }
  }

  await updateRoomStatus(roomId, roomStatus, stories, story, userId);
}

Future<void> skipStory(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId) async {
  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.skipped;
  story.currentStory = false;

  await clearVotes(roomId, story.id);
  await updateStory(roomId, story.id, {'status': roomStatus.toString()});
  await updateRoomStatus(roomId, roomStatus, stories, story, userId);
}

Future<void> flipCards(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId, List<Vote> votes) async {
  final validVotes = votes.where((e) => e.value.value != null);
  final validVotesSum = validVotes.map((e) => e.value.value).reduce((e, t) => e! + t!)!;
  story.estimate = double.parse((validVotesSum / validVotes.length).toStringAsFixed(2));
  story.revisedEstimate = null;
  story.status = StoryStatus.voted;

  await updateStory(roomId, story.id, {'revisedEstimate': null, 'status': story.status.toString()});
  await updateRoomStatus(roomId, roomStatus, stories, story, userId);
}

Future<void> moveStoryToActive(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId) async {
  if (story.status != StoryStatus.skipped) {
    return;
  }

  story.status = StoryStatus.notStarted;
  story.currentStory = false;

  await updateStory(roomId, story.id, {'currentStory': false, 'status': story.status.toString()});
  await updateRoomStatus(roomId, roomStatus, stories, story, userId);
}

Future<void> nextStory(String roomId, RoomStatus roomStatus, List<Story> stories, Story story, String userId) async {
  story.status = StoryStatus.ended;
  story.currentStory = false;

  await updateStory(roomId, story.id, {'currentStory': false, 'status': story.status.toString()});
  await updateRoomStatus(roomId, roomStatus, stories, story, userId);
}

Future<void> swapStories(String roomId, List<Story> stories, Story story1, Story story2) async {
  final index1 = stories.indexOf(story1);
  final index2 = stories.indexOf(story2);
  stories[index1] = story2;
  stories[index2] = story1;
  _setStoriesOrder(stories);
  story1.currentStory = false;
  story2.currentStory = false;

  await updateStory(roomId, story1.id, {'currentStory': false, 'status': story1.status.toString()});
  await updateStory(roomId, story2.id, {'currentStory': false, 'status': story2.status.toString()});
}

// votes
Future<void> clearStoryVotes(String roomId, Story story) async {
  if (story.status != StoryStatus.started) {
    return;
  }

  story.estimate = null;
  story.revisedEstimate = null;

  await clearVotes(roomId, story.id);
  await updateStory(roomId, story.id, {'estimate': null, 'revisedEstimate': null});
}

Future<void> clearVotes(String roomId, String storyId) async {
  final collection = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(storyId).collection('votes');
  final snapshots = await collection.get();

  for (final doc in snapshots.docs) {
    await doc.reference.delete();
  }
}

Future<void> saveVote(String roomId, String storyId, Vote vote) async {
  await FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('stories')
      .doc(storyId)
      .collection('votes')
      .doc(vote.userId)
      .set(vote.toJson(), SetOptions(merge: true));
}
