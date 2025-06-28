import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/voting/room_login.dart';
import 'package:scrum_poker/voting/voting_players.dart';
import 'package:scrum_poker/voting/voting_story_list.dart';
import 'package:scrum_poker/voting/voting_story.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:uuid/uuid.dart';

class RoomPage extends StatefulWidget {
  final String? roomId;
  const RoomPage({super.key, this.roomId});

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

  @override
  void initState() {
    loadUser();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void signOut() {
    _box!.delete('appUser');
    setState(() {
      if (user != null) {
        AuthServices().signOut().then((_) {
          navigatorKey.currentContext!.go(Routes.login);
        });
      }
      _appUser.value = null;
    });
  }

  Future<void> loadUser() async {
    setState(() {
      _isLoading = true;
    });

    _box = await Hive.openBox('scrumPoker');

    if (user?.metadata != null) {
      final appUser = AppUser.fromUser(user!);
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

    final appUser = user == null ? AppUser(name: username, id: Uuid().v4()) : AppUser.fromUser(user!);

    _box!.put('appUser', appUser.toJson());

    _appUser.value = appUser;
  }

  void setCurrentStory(Room room) {
    if (room.currentStory != null) return;
    room.stories.sort((a, b) => a.order.compareTo(b.order));
    final activeStories = room.stories.where((t) => [StoryStatus.notStarted, StoryStatus.started].contains(t.status)).toList();
    for (var i = 0; i < activeStories.length; i++) {
      if (i == 0) {
        activeStories[i].currentStory = true;
      } else {
        activeStories[i].currentStory = false;
      }
    }
    room_services.saveRoom(room);
  }

  Future<void> checkChanges(Room room) async {
    if (_oldRoom == null) {
      _oldRoom = room;
      return;
    }

    final messages = <String>[];

    // check users
    messages.addAll(getUserChanges(_oldRoom!.currentUsers ?? <AppUser>[], room.currentUsers ?? <AppUser>[]));

    // check stories
    messages.addAll(getStoryChanges(_oldRoom!.stories, room.stories));

    // current story change
    if (room.currentStory != null && _oldRoom!.currentStory?.id != room.currentStory!.id) {
      messages.add('Current story as changed. ${room.currentStory!.description} is now the current story.');
    }

    // check stories
    messages.addAll(getVoteChanges(_oldRoom!.currentStory?.votes ?? [], room.currentStory?.votes ?? []));

    _oldRoom = room;

    showSnackBar(messages);
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

  /// check users
  List<String> getUserChanges(List<AppUser> oldUsers, List<AppUser> newUsers) {
    final messages = <String>[];

    // check if there is a new user
    for (final user in newUsers) {
      if (user.id != _appUser.value?.id) {
        continue;
      }
      if (!oldUsers.any((t) => t.id == user.id)) {
        // new user
        messages.add('${user.name} joined the room.');
      } else {
        // check user changes
        final currentUser = oldUsers.firstWhere((t) => t.id == user.id);
        if (currentUser.observer != user.observer) {
          if (user.observer) {
            messages.add('${user.name} is now an observer.');
          } else {
            messages.add('${user.name} is now a player.');
          }
        }
      }
    }
    for (final user in oldUsers) {
      if (user.id != _appUser.value?.id) {
        continue;
      }
      if (!newUsers.any((t) => t.id == user.id)) {
        // user left
        messages.add('${user.name} left the room.');
      }
    }

    return messages;
  }

  /// check stories
  List<String> getStoryChanges(List<Story> oldStories, List<Story> newStories) {
    final messages = <String>[];
    for (final story in newStories) {
      final oldStory = oldStories.firstWhereOrNull((t) => t.id == story.id);
      if (oldStory != null) {
        // check status
        if (oldStory.status != story.status) {
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
      }
    }

    // check deleted stories
    for (final oldStory in oldStories) {
      final story = newStories.firstWhereOrNull((t) => t.id == oldStory.id);
      if (story == null) {
        messages.add('Story "${oldStory.description}" deleted.');
      }
    }

    return messages;
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
    await room_services.removeUser(appUser, room);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar:
          (_appUser.value == null)
              ? null
              : AppBar(
                actionsPadding: const EdgeInsets.only(right: 16.0),
                title: Text('Scrum Poker', style: theme.textTheme.displayMedium),
                actions: [CircleAvatar(backgroundColor: Colors.blueAccent, child: IconButton(icon: Icon(Icons.person_outline, color: Colors.white), onPressed: signOut))],
              ),
      body: ValueListenableBuilder(
        valueListenable: _appUser,
        builder:
            (ctx, value, child) =>
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

                        room_services.addUserToStory(_appUser.value, room);
                        setCurrentStory(room);

                        checkChanges(room);

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
                                    Expanded(child: Column(spacing: 20, children: [VotingStory(appUser: _appUser.value, roomId: room.id!), VotingStoryList(roomId: room.id!)])),
                                    VotingPlayers(roomId: room.id!, appUser: _appUser.value!, onUserRenamed: (appUser) => renameUser(appUser, room)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      ),
    );
  }
}
