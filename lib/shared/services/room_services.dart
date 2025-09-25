import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

////////
// room
////////

/// Get user rooms
/// 
/// [userId] the user Id
Future<List<Room>> getUserRooms(String userId) async {
  final dbRef = FirebaseFirestore.instance.collection('rooms');
  final dbRooms = await dbRef.get();
  final maps = dbRooms.docs.map((t) => t.data());

  return maps.map((t) => Room.fromJson(t)).where((r) => r.userId == userId).toList();
}

/// Save room
///
/// [room] room to save
Future<void> saveRoom(Room room) async {
  final json = room.toJson();
  await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(json);

  // save room under the user
  final dbRoom = await FirebaseFirestore.instance.collection('users').doc(room.userId).collection('rooms').doc(room.id).snapshots().first;
  final userRoom = Room.fromJson(dbRoom.data()!);
  room.status = userRoom.status;
  final roomMap = room.toJson();
  await FirebaseFirestore.instance.collection('users').doc(room.userId).collection('rooms').doc(room.id).update(roomMap);
}

/// Update room status
///
/// [roomId] room identifier
/// [stories] stories used to update the room status
Future<void> _updateRoomStatus(String roomId, List<Story> stories) async {
  final dataRoom = await FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots().first;
  final userRoom = Room.fromJson(dataRoom.data()!);
  final roomStatus = userRoom.status;
  final newRoomStatus = _getRoomStatus(stories);

  final activeStories = stories.where((t) => t.status.active).length;
  final skippedStories = stories.where((t) => t.status == StoryStatus.skipped).length;
  final completedStories = stories.where((t) => !t.status.active).length;

  if (newRoomStatus != roomStatus) {
    await _updateUserRoom(userRoom.id, userRoom.userId, {
      'status': $RoomStatusEnumMap[newRoomStatus],
      'activeStories': activeStories,
      'skippedStories': skippedStories,
      'completedStories': completedStories,
    });
  }
}

/// Update room in database
///
/// [roomId] room identifier
/// [userId] user identifier
/// [data] data to update
Future<void> _updateUserRoom(String roomId, String userId, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('rooms').doc(roomId);

  await docRef.update(data);
}

/// Get room status
///
/// [stories] list of room stories
RoomStatus _getRoomStatus(List<Story> stories) {
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

/// Update room user
///
/// [user] user to update
Future<void> updateRoomUserObserver(AppUser user) async {
  await _updateCurrentUser(user.roomId!, user.id, {'observer': user.observer});
}

/// Update room user on the database
///
/// [roomId] room identifier
/// [userId] user identifier
/// [data] data to update
Future<void> _updateCurrentUser(String roomId, String userId, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('currentUsers').doc(userId);
  await docRef.update(data);
}

/// Add user to room
///
/// [user] user to add
Future<void> addUserToRoom(AppUser? user) async {
  if (user == null) {
    return;
  }

  // add user to room
  await FirebaseFirestore.instance.collection('rooms').doc(user.roomId).collection('currentUsers').doc(user.id).set(user.toJson(), SetOptions(merge: true));
}

/// Remove user from room
///
/// [user] user to remove
Future<void> removeUser(AppUser user) async {
  await FirebaseFirestore.instance.collection('rooms').doc(user.roomId).collection('currentUsers').doc(user.id).delete();
}

/////////
// story
/////////

/// Get room stories
///
/// [roomId] room identifier
Future<List<Story>> getStories(String roomId) async {
  final dbRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories');
  final dbStories = await dbRef.get();
  final maps = dbStories.docs.map((t) => t.data());

  return maps.map((t) => Story.fromJson(t)).toList();
}

/// Update story in the database
///
/// [story] story to update
/// [data] data to update
Future<void> _updateStory(Story story, Map<String, dynamic> data) async {
  final docRef = FirebaseFirestore.instance.collection('rooms').doc(story.roomId).collection('stories').doc(story.id);

  await docRef.update(data);
}

/// Set current story
///
/// [stories] all room stories
Future<void> setCurrentStory(List<Story> stories) async {
  if (stories.any((t) => t.currentStory)) return;
  stories.sort((a, b) => a.order.compareTo(b.order));

  final activeStories = stories.where((t) => [StoryStatus.notStarted, StoryStatus.started, StoryStatus.voted].contains(t.status)).toList();
  for (var i = 0; i < activeStories.length; i++) {
    final story = activeStories[i];
    story.currentStory = i == 0;

    await _updateStory(story, {'currentStory': story.currentStory});
  }
}

/// Start story voting
///
/// [story] story that is started
Future<void> startStory(Story story) async {
  final stories = await getStories(story.roomId);
  story.status = StoryStatus.started;

  await _updateStory(story, {'status': $StoryStatusEnumMap[story.status]});
  await _updateRoomStatus(story.roomId, stories);
}

/// Move story up
///
/// [stories] list of stories
/// [story] story to move up
Future<void> moveStoryUp(List<Story> stories, Story story) async {
  final index = stories.indexOf(story);
  if (index == 0) return;

  final previousStory = stories[index - 1];
  stories[index - 1] = story;
  stories[index] = previousStory;

  await _moveStoryUpdate(stories, story, previousStory);
}

/// Move story down
///
/// [stories] list of stories
/// [story] story to move down
Future<void> moveStoryDown(List<Story> stories, Story story) async {
  final index = stories.indexOf(story);
  if (index == stories.length + 1) return;

  final nextStory = stories[index + 1];
  stories[index + 1] = story;
  stories[index] = nextStory;

  await _moveStoryUpdate(stories, story, nextStory);
}

/// Move story down
///
/// [stories] list of stories
/// [story1] story1 to update
/// [story2] story2 to update
Future<void> _moveStoryUpdate(List<Story> stories, Story story1, Story story2) async {
  story1.currentStory = false;
  story2.currentStory = false;
  _setStoriesOrder(stories);

  await _updateStory(story1, {'order': story1.order, 'currentStory': story1.currentStory});
  await _updateStory(story2, {'order': story2.order, 'currentStory': story2.currentStory});
  await _updateCurrentStory(stories, [story1.id, story2.id]);
}

/// Set all stories order
///
/// [stories] list of stories
void _setStoriesOrder(List<Story> stories) {
  for (var i = 0; i < stories.length; i++) {
    stories[i].order = i;
  }
}

/// Remove story from room
///
/// [stories] list of stories
/// [story] story to remove
Future<void> removeStory(List<Story> stories, Story story) async {
  await FirebaseFirestore.instance.collection('rooms').doc(story.roomId).collection('stories').doc(story.id).delete();
  story.currentStory = false;
  stories.remove(story);

  for (var i = 0; i < stories.length; i++) {
    final story = stories[i];
    if (stories[i].order != i) {
      stories[i].order = i;
      await _updateStory(story, {'order': story.order});
    }
  }

  await _updateRoomStatus(story.roomId, stories);
}

/// Skip story voting
///
/// [story] story to skip
Future<void> skipStory(Story story) async {
  final stories = await getStories(story.roomId);
  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.skipped;
  story.currentStory = false;

  await clearVotes(story);
  await _updateStory(story, {
    'estimate': story.revisedEstimate,
    'revisedEstimate': story.estimate,
    'status': $StoryStatusEnumMap[story.status],
    'currentStory': story.currentStory,
  });

  await _updateCurrentStory(stories, [story.id]);

  await _updateRoomStatus(story.roomId, stories);
}

/// Flip story cards
///
/// [story] story were cards are flipped
/// [votes] list of votes
Future<void> flipCards(Story story, List<Vote> votes) async {
  final validVotes = votes.where((e) => e.value.value != null).toList();
  final validVotesSum = validVotes.map((e) => e.value.value).reduce((e, t) => e! + t!)!;
  story.estimate = double.parse((validVotesSum / validVotes.length).toStringAsFixed(2));
  story.revisedEstimate = null;
  story.status = StoryStatus.voted;
  await updateVotes(votes, story.status);
  final stories = await getStories(story.roomId);

  await _updateStory(story, {'estimate': story.estimate, 'revisedEstimate': story.revisedEstimate, 'status': $StoryStatusEnumMap[story.status]});
  await _updateRoomStatus(story.roomId, stories);
}

/// Move a skipped story to active tab
///
/// [stories] list of stories in a room
/// [story] story to be moved
Future<void> moveStoryToActive(List<Story> stories, Story story) async {
  if (story.status != StoryStatus.skipped) {
    return;
  }

  story.status = StoryStatus.notStarted;
  story.currentStory = false;

  await _updateStory(story, {'currentStory': false, 'status': $StoryStatusEnumMap[story.status]});

  final currentStory = stories.firstWhereOrNull((t) => t.currentStory);

  if (currentStory != null && currentStory.id != story.id) {
    currentStory.currentStory = false;
    await _updateStory(currentStory, {'currentStory': currentStory.currentStory});
  }
  await _updateRoomStatus(story.roomId, stories);
}

/// Move to next story
///
/// [story] story to be ended
/// [votes] story votes
Future<void> nextStory(Story story, List<Vote> votes) async {
  final stories = await getStories(story.roomId);
  story.status = StoryStatus.ended;
  story.currentStory = false;
  await updateVotes(votes, story.status);

  await _updateStory(story, {'currentStory': false, 'status': $StoryStatusEnumMap[story.status]});
  await _updateRoomStatus(story.roomId, stories);
}

/// Swap stories
///
/// [stories] list of stories in a room
/// [oldIndex] story 1 to be swapped with story 2
/// [newIndex] story 2 to be swapped with story 1
Future<void> swapStories(List<Story> stories, int oldIndex, int newIndex) async {
  final storyToMove = stories[oldIndex];
  stories.removeWhere((t) => t.id == storyToMove.id);
  stories.insert(newIndex, storyToMove);
  _setStoriesOrder(stories);

  for (final story in stories) {
    if (story.id == storyToMove.id) {
      await _updateStory(story, {'currentStory': false, 'status': $StoryStatusEnumMap[story.status], 'order:': story.order});
    } else {
      await _updateStory(story, {'currentStory': false, 'order:': story.order});
    }
  }
}

/// Update revised estimate
///
/// [story] story to be updated
Future<void> updateRevisedEstimate(Story story) async {
  await _updateStory(story, {'revisedEstimate': story.revisedEstimate});
}

/// Update current story field
///
/// [stories] list of stories in a room
/// [storyIds] stories where currentStory field is already updated
Future<void> _updateCurrentStory(List<Story> stories, List<String>? storyIds) async {
  final currentStory = stories.firstWhereOrNull((t) => t.currentStory);

  if (currentStory != null && (storyIds == null || !storyIds.contains(currentStory.id))) {
    currentStory.currentStory = false;
    await _updateStory(currentStory, {'currentStory': currentStory.currentStory});
  }
}

/////////
// votes
/////////

/// Update story votes
///
/// [votes] list of votes
/// [storyStatus] story status to update on votes
Future<void> updateVotes(List<Vote> votes, StoryStatus storyStatus) async {
  for (final vote in votes) {
    vote.storyStatus = storyStatus;
    await updateVote(vote);
  }
}

/// Clear current story votes
///
/// [story] story to be updated
Future<void> clearStoryVotes(Story story) async {
  if (![StoryStatus.voted, StoryStatus.started].contains(story.status)) {
    snackbarMessenger(message: 'This story is not in progress.', type: SnackBarType.warning);
    return;
  }

  story.estimate = null;
  story.revisedEstimate = null;
  story.status = StoryStatus.started;

  await clearVotes(story);
  await _updateStory(story, {'estimate': story.estimate, 'revisedEstimate': story.revisedEstimate, 'status': $StoryStatusEnumMap[story.status]});
}

/// Remove votes
///
/// [story] story to be updated
Future<void> clearVotes(Story story) async {
  final collection = FirebaseFirestore.instance.collection('rooms').doc(story.roomId).collection('stories').doc(story.id).collection('votes');
  final snapshots = await collection.get();

  for (final doc in snapshots.docs) {
    await doc.reference.delete();
  }
}

/// Update votes
///
/// [vote] vote to be updated
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
