import 'dart:convert';
import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/shared/widgets/app_bar.dart';
import 'package:scrum_poker/voting/room_login.dart';
import 'package:scrum_poker/voting/voting_players.dart';
import 'package:scrum_poker/voting/voting_story_list.dart';
import 'package:scrum_poker/voting/voting_story.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop' as js;

class RoomPage extends StatefulWidget {
  final String roomId;
  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _appUser = ValueNotifier<AppUser?>(null);

  bool _isLoading = true;
  Box? _box;
  bool invalidRoom = false;
  Room? _oldRoom;
  final _oldCurrentUsers = <AppUser>[];
  final _oldStories = <Story>[];
  bool listenToRoomChanges = false;
  bool listenToStoryChanges = false;
  bool listenToUserChanges = false;

  final currentStoryVN = ValueNotifier<Story?>(null);
  final votesVN = ValueNotifier<List<Vote>>([]);

  @override
  void initState() {
    final roomsStream = FirebaseFirestore.instance.collection('rooms').snapshots(includeMetadataChanges: true);
    final storiesStream = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('stories').snapshots(includeMetadataChanges: true);
    final currentUsersStream = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('currentUsers').snapshots(includeMetadataChanges: true);

    roomsStream.listen(onRoomsData);
    storiesStream.listen(onStoriesData);
    currentUsersStream.listen(onCurrentUsersData);

    web.window.onbeforeunload =
        (JSAny data) {
          if (_appUser.value != null) {
            room_services.removeUser(widget.roomId, _appUser.value!.id);
          }
        }.toJS;

    web.window.onpopstate =
        (JSAny data) {
          if (_appUser.value != null) {
            room_services.removeUser(widget.roomId, _appUser.value!.id);
          }
        }.toJS;

    loadUser();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onRoomsData(QuerySnapshot<Map<String, dynamic>> event) {
    if (event.docChanges.isNotEmpty && listenToRoomChanges) {
      final rooms = event.docChanges.where((t) => t.doc.data() != null).map((t) => Room.fromJson(t.doc.data()!)).toList();
      print(rooms);
    }
    listenToRoomChanges = true;
  }

  void onStoriesData(QuerySnapshot<Map<String, dynamic>> event) {
    if (event.docChanges.isNotEmpty && listenToStoryChanges) {
      final messages = <String>[];
      final stories = event.docs.map((t) => Story.fromJson(t.data())).toList();
      for (final change in event.docChanges) {
        if (change.doc.exists) {
          final story = Story.fromJson(change.doc.data()!);
          switch (change.type) {
            case DocumentChangeType.added:
              messages.add('${story.description} has been added to the room.');
              break;
            case DocumentChangeType.removed:
              messages.add('${story.description} has been remove from the room.');
              break;
            case DocumentChangeType.modified:
              final oldStory = _oldStories.firstWhereOrNull((t) => t.id == story.id);
              // check status
              if (oldStory?.status != story.status) {
                if (story.status == StoryStatus.notStarted) {
                  messages.add('Story "${story.description}" was moved to active.');
                }
                if (story.status == StoryStatus.skipped) {
                  messages.add('Story "${story.description}" was skipped.');
                }
                if (story.status == StoryStatus.voted) {
                  messages.add('Story "${story.description}" cards were flipped.');
                }
                if (story.status == StoryStatus.ended) {
                  messages.add('Story "${story.description}" has ended.');
                }
              }

              if (oldStory?.currentStory != story.currentStory && story.currentStory) {
                messages.add('Current story as changed. "${story.description}" is now the current story.');
              }
          }
        }
      }
      _oldStories.clear();
      _oldStories.addAll(stories);
      showSnackBar(messages);
    }
    listenToStoryChanges = true;
  }

  void onCurrentUsersData(QuerySnapshot<Map<String, dynamic>> event) {
    if (event.docChanges.isNotEmpty && listenToUserChanges) {
      final messages = <String>[];
      final users = event.docs.map((t) => AppUser.fromJson(t.data())).toList();
      for (final change in event.docChanges) {
        if (change.doc.exists) {
          final user = AppUser.fromJson(change.doc.data()!);
          switch (change.type) {
            case DocumentChangeType.added:
              if (user.id != _appUser.value?.id) {
                messages.add('${user.name} joined the room.');
              }
              break;
            case DocumentChangeType.removed:
              if (user.id != _appUser.value?.id) {
                messages.add('${user.name} left the room.');
              }
              break;
            case DocumentChangeType.modified:
              final oldUser = _oldCurrentUsers.firstWhereOrNull((t) => t.id == user.id);
              if (oldUser?.observer != user.observer) {
                if (user.observer) {
                  messages.add('${user.name} is now an observer.');
                } else {
                  messages.add('${user.name} is now a player.');
                }
              }
          }
        }
      }
      _oldCurrentUsers.clear();
      _oldCurrentUsers.addAll(users);
      showSnackBar(messages);
    }
    listenToUserChanges = true;
  }

  Future<void> loadUser() async {
    setState(() {
      _isLoading = true;
    });

    _box = await Hive.openBox('scrumPoker');

    if (user?.metadata != null) {
      final appUser = AppUser.fromUser(user!, widget.roomId);
      _box!.put('appUser', appUser.toJson());
    }

    final appUserMap = _box!.get('appUser');
    if (appUserMap != null) {
      final map = jsonDecode(jsonEncode(appUserMap));
      _appUser.value = AppUser.fromJson(map);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> logIn(String username) async {
    if (user != null && user!.displayName != username) {
      await user!.updateDisplayName(username);
    }

    final appUser = user == null ? AppUser(name: username, id: Uuid().v4()) : AppUser.fromUser(user!, widget.roomId);

    _box!.put('appUser', appUser.toJson());

    _appUser.value = appUser;
  }

  void showSnackBar(List<String> messages) {
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;

    // show messages
    for (final message in messages) {
      final duration = Duration(milliseconds: controller == null ? 0 : 1000);
      Future.delayed(duration, () {
        controller = ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blueAccent[200],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text(message),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentSnackBar();
              },
            ),
          ),
        );
      });
    }
  }

  List<String> getVoteChanges(List<Vote> oldVotes, List<Vote> newVotes) {
    final messages = <String>[];
    for (final newVote in newVotes) {
      final oldVote = oldVotes.firstWhereOrNull((t) => t.userId == newVote.userId);
      if (oldVote == null) {
        messages.add('${newVote.userName} just voted.');
      } else if (oldVote.value != newVote.value) {
        messages.add('${newVote.userName} changed his/her vote.');
      }
    }

    return messages;
  }

  Future<void> renameUser(AppUser appUser, Room room) async {
    _appUser.value = null;
    await room_services.removeUser(appUser.id, room.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: _appUser,
      builder: (ctx, value, child) {
        return Scaffold(
          key: Key('${_appUser.value}'),
          appBar:
              (_appUser.value == null)
                  ? null
                  : GiraffeAppBar(
                    onSignOut: () {
                      room_services.removeUser(widget.roomId, _appUser.value!.id);
                      setState(() {
                        _appUser.value = null;
                      });
                    },
                  ),
          body:
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : (_appUser.value == null)
                  ? RoomLogin(isModerator: user != null, login: logIn)
                  : StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      final map = snapshot.data!.data()!;
                      final room = Room.fromJson(map);

                      _appUser.value!.roomId = room.id;

                      room_services.addUserToRoom(_appUser.value);

                      return StreamBuilder(
                        stream: FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('stories').snapshots(),
                        builder: (context, snapshot) {
                          final maps = snapshot.data?.docs.map((t) => t.data());
                          final stories = maps?.map((t) => Story.fromJson(t)).toList() ?? <Story>[];
                          stories.sortBy((t) => t.order);

                          if (user != null) {
                            room_services.setCurrentStory(stories);
                          }

                          currentStoryVN.value = stories.firstWhereOrNull((t) => t.currentStory);

                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(room.name!, style: theme.textTheme.headlineLarge),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 20,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          spacing: 20,
                                          children: [
                                            VotingStory(
                                              appUser: _appUser.value,
                                              roomId: room.id,
                                              votesChanged: (votes) {
                                                votesVN.value = votes;
                                              },
                                            ),
                                            VotingStoryList(room: room),
                                          ],
                                        ),
                                      ),

                                      VotingPlayers(
                                        currentStoryVN: currentStoryVN,
                                        votesVN: votesVN,
                                        room: room,
                                        appUser: _appUser.value!,
                                        onUserRenamed: (appUser) => renameUser(appUser, room),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
        );
      },
    );
  }
}
