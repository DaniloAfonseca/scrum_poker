import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

////////
// room
////////

Future<void> saveRoom(Room room) async {
  final json = room.toJson();
  await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(json);

  final dbRoom = await FirebaseFirestore.instance.collection('users').doc(room.userId).collection('rooms').doc(room.id).snapshots().first;
  final userRoom = Room.fromJson(dbRoom.data()!);
  room.status = userRoom.status;
  final roomMap = room.toJson();
  await FirebaseFirestore.instance.collection('users').doc(room.userId).collection('rooms').doc(room.id).update(roomMap);
}

Future<void> updateRoomStatus(Room room, List<Story> stories) async {
  final roomStatus = room.status;
  final newRoomStatus = getRoomStatus(stories);
  if (newRoomStatus != roomStatus) {
    await updateRoom(room.id, room.userId, {'status': $RoomStatusEnumMap[roomStatus]});
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

Future<void> addUserToRoom(AppUser? appUser) async {
  if (appUser == null) {
    return;
  }

  // add user to room
  await FirebaseFirestore.instance.collection('rooms').doc(appUser.roomId).collection('currentUsers').doc(appUser.id).set(appUser.toJson(), SetOptions(merge: true));
}

Future<void> removeUser(String roomId, String userId) async {
  await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('currentUsers').doc(userId).delete();
}

/////////
// story
/////////

Future<List<Story>> getStories(String roomId) async {
  final dbRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories');
  final dbStories = await dbRef.get();
  final maps = dbStories.docs.map((t) => t.data());

  return maps.map((t) => Story.fromJson(t)).toList();
}

Future<void> updateStory(Story story, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(story.roomId).collection('stories').doc(story.id);

  await docRef.update(data);
}

Future<void> setCurrentStory(List<Story> stories) async {
  if (stories.any((t) => t.currentStory)) return;
  stories.sort((a, b) => a.order.compareTo(b.order));
  final activeStories = stories.where((t) => [StoryStatus.notStarted, StoryStatus.started, StoryStatus.voted].contains(t.status)).toList();
  for (var i = 0; i < activeStories.length; i++) {
    final story = activeStories[i];
    story.currentStory = i == 0;

    await updateStory(story, {'currentStory': story.currentStory});
  }
}

Future<void> storyStart(Room room, Story story) async {
  final stories = await getStories(room.id);
  story.status = StoryStatus.started;

  await updateStory(story, {'status': $StoryStatusEnumMap[story.status]});
  await updateRoomStatus(room, stories);
}

Future<void> moveStoryUp(List<Story> stories, Story story) async {
  final index = stories.indexOf(story);
  final previousStory = stories[index - 1];
  stories[index - 1] = story;
  stories[index] = previousStory;
  story.currentStory = false;
  _setStoriesOrder(stories);

  await updateStory(story, {'order': story.order, 'currentStory': story.currentStory});
  await updateStory(previousStory, {'order': previousStory.order});
}

Future<void> moveStoryDown(List<Story> stories, Story story) async {
  final index = stories.indexOf(story);
  final nextStory = stories[index + 1];
  stories[index + 1] = story;
  stories[index] = nextStory;
  story.currentStory = false;
  _setStoriesOrder(stories);

  await updateStory(story, {'order': story.order, 'currentStory': story.currentStory});
  await updateStory(nextStory, {'order': nextStory.order});
}

void _setStoriesOrder(List<Story> stories) {
  for (var i = 0; i < stories.length; i++) {
    stories[i].order = i;
  }
}

Future<void> removeStory(Room room, List<Story> stories, Story story) async {
  await FirebaseFirestore.instance.collection('rooms').doc(story.roomId).collection('stories').doc(story.id).delete();
  story.currentStory = false;
  stories.remove(story);

  for (var i = 0; i < stories.length; i++) {
    final story = stories[i];
    if (stories[i].order != i) {
      stories[i].order = i;
      await updateStory(story, {'order': story.order});
    }
  }

  await updateRoomStatus(room, stories);
}

Future<void> skipStory(Room room, Story story) async {
  final stories = await getStories(room.id);
  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.skipped;
  story.currentStory = false;

  await clearVotes(story);
  await updateStory(story, {'estimate': story.revisedEstimate, 'revisedEstimate': story.estimate, 'status': $StoryStatusEnumMap[story.status], 'currentStory': story.currentStory});
  await updateRoomStatus(room, stories);
}

Future<void> flipCards(Room room, Story story, List<Vote> votes) async {
  final stories = await getStories(room.id);
  final validVotes = votes.where((e) => e.value.value != null);
  final validVotesSum = validVotes.map((e) => e.value.value).reduce((e, t) => e! + t!)!;
  story.estimate = double.parse((validVotesSum / validVotes.length).toStringAsFixed(2));
  story.revisedEstimate = null;
  story.status = StoryStatus.voted;
  await updateVotes(votes, story.status);

  await updateStory(story, {'estimate': story.estimate, 'revisedEstimate': story.revisedEstimate, 'status': $StoryStatusEnumMap[story.status]});
  await updateRoomStatus(room, stories);
}

Future<void> updateRevisedEstimate(Story story) async {
  await updateStory(story, {'revisedEstimate': story.revisedEstimate});
}

Future<void> moveStoryToActive(Room room, List<Story> stories, Story story) async {
  if (story.status != StoryStatus.skipped) {
    return;
  }

  story.status = StoryStatus.notStarted;
  story.currentStory = false;

  await updateStory(story, {'currentStory': false, 'status': $StoryStatusEnumMap[story.status]});
  await updateRoomStatus(room, stories);
}

Future<void> nextStory(Room room, Story story, List<Vote> votes) async {
  final stories = await getStories(room.id);
  story.status = StoryStatus.ended;
  story.currentStory = false;
  await updateVotes(votes, story.status);

  await updateStory(story, {'currentStory': false, 'status': $StoryStatusEnumMap[story.status]});
  await updateRoomStatus(room, stories);
}

Future<void> swapStories(List<Story> stories, Story story1, Story story2) async {
  final index1 = stories.indexOf(story1);
  final index2 = stories.indexOf(story2);
  stories[index1] = story2;
  stories[index2] = story1;
  _setStoriesOrder(stories);
  story1.currentStory = false;
  story2.currentStory = false;

  await updateStory(story1, {'currentStory': false, 'status': $StoryStatusEnumMap[story1.status]});
  await updateStory(story2, {'currentStory': false, 'status': $StoryStatusEnumMap[story2.status]});
}

/////////
// votes
/////////

Future<void> updateVotes(List<Vote> votes, StoryStatus storyStatus) async {
  for (final vote in votes) {
    vote.storyStatus = storyStatus;
    await updateVote(vote);
  }
}

Future<void> clearStoryVotes(Story story) async {
  if (![StoryStatus.voted, StoryStatus.started].contains(story.status)) {
    snackbarMessenger(navigatorKey.currentContext!, message: 'This story is not in progress.', type: SnackBarType.warning);
    return;
  }

  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.started;

  await clearVotes(story);
  await updateStory(story, {'estimate': story.estimate, 'revisedEstimate': story.revisedEstimate, 'status': $StoryStatusEnumMap[story.status]});
}

Future<void> clearVotes(Story story) async {
  final collection = FirebaseFirestore.instance.collection('rooms').doc(story.roomId).collection('stories').doc(story.id).collection('votes');
  final snapshots = await collection.get();

  for (final doc in snapshots.docs) {
    await doc.reference.delete();
  }
}

Future<void> updateVote(Vote vote) async {
  await FirebaseFirestore.instance
      .collection('rooms')
      .doc(vote.roomId)
      .collection('stories')
      .doc(vote.storyId)
      .collection('votes')
      .doc(vote.userId)
      .set(vote.toJson(), SetOptions(merge: true));
}
