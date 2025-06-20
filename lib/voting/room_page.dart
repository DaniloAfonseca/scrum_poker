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
  final oldStories = <Story>[];
  bool firstLoad = true;
  final currentUsers = <AppUser>[];

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

  Future<void> logIn(username) async {
    if (user == null) return;

    await user!.updateDisplayName(username);

    final appUser = user == null ? AppUser(name: username, id: Uuid().v4()) : AppUser.fromUser(user!);

    _box!.put('appUser', appUser.toJson());

    _appUser.value = appUser;
  }

  void setCurrentStory(Room room) {
    if (room.currentStory != null) return;
    room.stories.sort((a, b) => a.order.compareTo(b.order));
    final activeStories = room.stories.where((t) => [StatusEnum.notStarted, StatusEnum.started].contains(t.status)).toList();
    if (activeStories.isNotEmpty) {
      room.currentStory = activeStories.first;
      room_services.saveRoom(room);
    }
  }

  Future<void> checkChanges(Room room) async {
    if (firstLoad) return;
    final messages = <String>[];

    // check users
    if (currentUsers.isNotEmpty && room.currentUsers != null && room.currentUsers!.isNotEmpty) {
      // check if there is a new user
      for (final user in room.currentUsers!) {
        if (user.id != _appUser.value?.id) {
          continue;
        }
        if (!currentUsers.any((t) => t.id == user.id)) {
          // new user
          messages.add('${user.name} joined the room.');
        } else {
          // check user changes
          final currentUser = currentUsers.firstWhere((t) => t.id == user.id);
          if (currentUser.observer != user.observer) {
            if (user.observer) {
              messages.add('${user.name} is now an observer.');
            } else {
              messages.add('${user.name} is now a player.');
            }
          }
        }
      }
      for (final user in currentUsers) {
        if (user.id != _appUser.value?.id) {
          continue;
        }
        if (!room.currentUsers!.any((t) => t.id == user.id)) {
          // user left
          messages.add('${user.name} left the room.');
        }
      }
    } else if (currentUsers.isEmpty && room.currentUsers != null && room.currentUsers!.isNotEmpty) {
      // new users joined
      for (final user in room.currentUsers!) {
        if (user.id != _appUser.value?.id) {
          continue;
        }
        messages.add('${user.name} joined the room.');
      }
    }

    // check stories
    if (oldStories.isNotEmpty) {
      for (final story in room.stories) {
        final oldStory = oldStories.firstWhereOrNull((t) => t.id == story.id);
        if (oldStory != null) {
          // check status
          if (oldStory.status != story.status) {
            if (story.status == StatusEnum.notStarted) {
              messages.add('Story "${story.description}" moved to active.');
            }
            if (story.status == StatusEnum.skipped) {
              messages.add('Story "${story.description}" skipped.');
            }
            if (story.status == StatusEnum.ended) {
              messages.add('Story "${story.description}" ended.');
            }
          }
        }
      }

      // check deleted
      for (final oldStory in oldStories) {
        final story = room.stories.firstWhereOrNull((t) => t.id == oldStory.id);
        if (story == null) {
          messages.add('Story "${oldStory.description}" deleted.');
        }
      }
    }

    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;

    // show messages
    for (final message in messages) {
      final duration = Duration(milliseconds: controller == null ? 0 : 1000);
      Future.delayed(duration, () {
        controller = ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blueAccent[200],
            behavior: SnackBarBehavior.floating,
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
                        oldStories.clear();
                        oldStories.addAll(room.stories);
                        firstLoad = false;

                        currentUsers.addAll(room.currentUsers ?? []);
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
