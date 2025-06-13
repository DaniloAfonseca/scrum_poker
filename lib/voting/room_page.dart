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
import 'package:scrum_poker/voting/voting_stories.dart';
import 'package:scrum_poker/voting/voting_story.dart';
import 'package:scrum_poker/shared/models/app_user.dart';

class RoomPage extends StatefulWidget {
  final String? roomId;
  const RoomPage({super.key, this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final _appUser = ValueNotifier<AppUser?>(null);
  bool _isLoading = true;
  Box? _box;
  bool invalidRoom = false;
  AppUser? user;
  final currentStory = ValueNotifier<Story?>(null);
  final currentMessage = ValueNotifier<String>('');
  final currentUsers = ValueNotifier<List<AppUser>>([]);

  @override
  void initState() {
    loadUser();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadUser() async {
    setState(() {
      _isLoading = true;
    });

    _box = await Hive.openBox('scrumPoker');

    if (firebaseUser != null) {
      user = await getUser(firebaseUser!.uid);
      final appUser = AppUser.fromAppUser(user!, true);
      _box!.put('appUser', appUser.toJson());
      addUserToStory(appUser);
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

  Future<void> addUserToStory(AppUser appUser) async {
    final room = await getRoom();
    if (room == null) {
      invalidRoom = true;
      return;
    }

    // add user to room
    if (room.currentUsers?.any((t) => t.name == appUser.name) != true) {
      room.currentUsers ??= [];
      room.currentUsers!.add(appUser);
      final roomMap = room.toJson();
      await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(roomMap);
    }

    final notStartedStories = room.stories.where((t) => t.status == StoryStatusEnum.newStory).toList();
    if (notStartedStories.isNotEmpty) {
      currentStory.value = notStartedStories.first;
    }

    // add user to moderator room
    final user = await getUser(room.userId);
    final userRoom = user!.rooms!.firstWhere((t) => t.id == room.id);
    if (userRoom.currentUsers?.any((t) => t.name == appUser.name) != true) {
      userRoom.currentUsers ??= [];
      userRoom.currentUsers!.add(appUser);
      final userMap = user.toJson();
      await FirebaseFirestore.instance.collection('users').doc(room.userId).set(userMap);
    }
  }

  Future<Room?> getRoom() async {
    final roomDoesNotExists = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots().isEmpty;
    if (!roomDoesNotExists) {
      final dbRoom = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots().first;
      final map = dbRoom.data()!;
      return Room.fromJson(map);
    }
    return null;
  }

  Future<AppUser?> getUser(String userId) async {
    final dbUser = await FirebaseFirestore.instance.collection('users').doc(userId).snapshots().first;
    final map = dbUser.data()!;

    return AppUser.fromJson(map);
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
                actions: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: Icon(Icons.person_outline, color: Colors.white),
                      onPressed: () {
                        _box!.delete('username');
                        setState(() {
                          if (firebaseUser != null) {
                            AuthServices().signOut().then((_) {
                              navigatorKey.currentContext!.go(Routes.login);
                            });
                          }
                          _appUser.value = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
      body: ValueListenableBuilder(
        valueListenable: _appUser,
        builder:
            (ctx, value, child) =>
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : (_appUser.value == null)
                    ? RoomLogin(
                      login: (username) {
                        final appUser = AppUser(name: username);

                        _box!.put('appUser', appUser.toJson());

                        _appUser.value = appUser;
                        addUserToStory(appUser);
                      },
                    )
                    : StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                        final map = snapshot.data!.data()!;
                        final room = Room.fromJson(map);

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
                                        children: [VotingStory(roomId: widget.roomId!, cards: room.cardsToUse, story: currentStory), VotingStories(room: room)],
                                      ),
                                    ),
                                    VotingPlayers(currentMessage: currentMessage, currentStory: currentStory, currentUsers: currentUsers, appUser: _appUser.value!),
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