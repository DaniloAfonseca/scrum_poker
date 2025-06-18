import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final currentStory = ValueNotifier<Story?>(null);
  final currentMessage = ValueNotifier<String>('');
  final currentUsers = ValueNotifier<List<AppUser>>([]);
  final oldStories = <Story>[];
  bool firstLoad = true;

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
      currentMessage.value = 'Click "Start" to begin voting';
    } else {
      currentMessage.value = 'Waiting for moderator';
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
    if (user != null) {
      await user!.updateDisplayName(username);
    }
    final appUser = user == null ? AppUser(name: username, id: Uuid().v4()) : AppUser.fromUser(user!);

    _box!.put('appUser', appUser.toJson());

    _appUser.value = appUser;
  }

  Future<void> addUserToStory(Room room) async {
    if (_appUser.value == null) {
      return;
    }

    // add user to room
    if (room.currentUsers?.any((t) => t.id == _appUser.value!.id) != true) {
      room.currentUsers ??= [];
      room.currentUsers!.add(_appUser.value!);
      final roomMap = room.toJson();
      await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(roomMap);
    }
  }

  void setCurrentStory(Room room) {
    final notStartedStories = room.stories.where((t) => t.status == StatusEnum.notStarted).toList();
    if (notStartedStories.isNotEmpty) {
      currentStory.value = notStartedStories.first;
    }
  }

  Future<void> checkChanges(Room room) async {
    if (firstLoad) return;
    final messages = <String>[];

    // check users
    if (currentUsers.value.isNotEmpty && room.currentUsers != null && room.currentUsers!.isNotEmpty) {
      // check if there is a new user
      for (final user in room.currentUsers!) {
        if (!currentUsers.value.any((t) => t.id == user.id)) {
          // new user
          messages.add('${user.name} joined the room.');
        } else {
          // check user changes
          final currentUser = currentUsers.value.firstWhere((t) => t.id == user.id);
          if (currentUser.observer != user.observer) {
            if (user.observer) {
              messages.add('${user.name} is now an observer.');
            } else {
              messages.add('${user.name} is now a player.');
            }
          }
        }
      }
      for (final user in currentUsers.value) {
        if (!room.currentUsers!.any((t) => t.id == user.id)) {
          // user left
          messages.add('${user.name} left the room.');
        }
      }
    } else if (currentUsers.value.isEmpty && room.currentUsers != null && room.currentUsers!.isNotEmpty) {
      // new users joined
      for (final user in room.currentUsers!) {
        messages.add('${user.name} joined the room.');
      }
    }

    // check stories
    if (oldStories.isNotEmpty) {
      for (final story in room.stories) {}
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

  Future<void> removeUser(AppUser appUser, Room room) async {
    room.currentUsers?.removeWhere((t) => t.name == appUser.name);
    await saveRoom(room);
  }

  Future<void> saveRoom(Room room) async {
    final json = room.toJson();
    await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(json);
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

                        addUserToStory(room);
                        if (_appUser.value!.moderator) {
                          setCurrentStory(room);
                        }

                        checkChanges(room);
                        oldStories.clear();
                        oldStories.addAll(room.stories);
                        firstLoad = false;

                        currentUsers.value = room.currentUsers ?? [];
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
                                          VotingStory(roomId: widget.roomId!, cards: room.cardsToUse, story: currentStory),
                                          VotingStoryList(room: room, currentStory: currentStory),
                                        ],
                                      ),
                                    ),
                                    VotingPlayers(
                                      currentMessage: currentMessage,
                                      currentStory: currentStory,
                                      currentUsers: currentUsers,
                                      appUser: _appUser.value!,
                                      onUserRemoved: (appUser) => removeUser(appUser, room),
                                      onObserverChanged: (appUser) => saveRoom(room),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        //Column(children: [Expanded(child: TextField(decoration: InputDecoration(labelText: 'Jira Issue Key'))), Expanded(child: VoteBoard()), VotingCards()]),
      ),
    );
  }
}


//functions/index.js (Firebase Cloud Function for Jira integration)
// const functions = require("firebase-functions");
// const axios = require("axios");

// exports.updateStoryPoints = functions.https.onCall(async (data, context) => {
//   const { issueKey, points, userToken } = data;
//   const JIRA_DOMAIN = "your-domain.atlassian.net";
//   const SHARED_API_TOKEN = "base64_encoded_email:token";

//   const authHeader = userToken
//     ? `Bearer ${userToken}`
//     : `Basic ${SHARED_API_TOKEN}`;

//   const url = `https://${JIRA_DOMAIN}/rest/api/3/issue/${issueKey}`;

//   try {
//     const response = await axios.put(
//       url,
//       {
//         fields: {
//           customfield_10016: points,
//         },
//       },
//       {
//         headers: {
//           Authorization: authHeader,
//           Accept: "application/json",
//           "Content-Type": "application/json",
//         },
//       }
//     );
//     return { status: "success", data: response.data };
//   } catch (error) {
//     console.error("Jira Update Failed", error.response?.data || error.message);
//     throw new functions.https.HttpsError('unknown', 'Jira update failed');
//   }
// });