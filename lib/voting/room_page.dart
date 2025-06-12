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
import 'package:scrum_poker/voting/voting_story.dart';
import 'package:scrum_poker/shared/models/user.dart' as u;

class RoomPage extends StatefulWidget {
  final String? roomId;
  const RoomPage({super.key, this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  String? _username;
  bool _isLoading = true;
  Box? _box;
  bool invalidRoom = false;
  String currentMessage = '';
  u.User? user;
  var currentStory = ValueNotifier<Story?>(null);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    setState(() {
      _isLoading = true;
    });

    _box = await Hive.openBox('scrumPoker');

    if (firebaseUser != null) {
      user = await getUser(firebaseUser!.uid);

      _box!.put('username', user!.name);
      addUserToStory(user!.name);
      setState(() {
        currentMessage = 'Click "Start" to begin voting';
      });
    } else {
      setState(() {
        currentMessage = 'Waiting for moderator';
      });
    }

    setState(() {
      _username = _box!.get('username');
      _isLoading = false;
    });
  }

  Future<void> addUserToStory(String username) async {
    final room = await getRoom();
    if (room == null) {
      invalidRoom = true;
      return;
    }

    // add user to room
    if (room.currentUsers?.contains(username) != true) {
      room.currentUsers ??= [];
      room.currentUsers!.add(username);
      final roomMap = room.toJson();
      await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(roomMap);
    }

    final notStartedStories = room.stories.where((t) => t.status == StoryStatusEnum.newStory).toList();
    if (notStartedStories.isNotEmpty) {
      currentStory.value = notStartedStories.first;
    }

    // add user to moderator romm
    final user = await getUser(room.userId);
    final userRoom = user!.rooms.firstWhere((t) => t.id == room.id);
    if (userRoom.currentUsers?.contains(username) != true) {
      userRoom.currentUsers ??= [];
      userRoom.currentUsers!.add(username);
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

  Future<u.User?> getUser(String userId) async {
    final dbUser = await FirebaseFirestore.instance.collection('users').doc(userId).snapshots().first;
    final map = dbUser.data()!;

    return u.User.fromJson(map);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar:
          (_username == null)
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
                          _username = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : (_username == null)
              ? RoomLogin(
                login: (username) {
                  _box!.put('username', username);
                  setState(() async {
                    _username = username;
                    addUserToStory(username);
                    //room = await FirebaseFirestore.instance.collection('room').doc(widget.roomId).snapshots().first;
                  });
                },
              )
              : StreamBuilder(
                stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final map = snapshot.data!.data()!;
                  final room = Room.fromJson(map);
                  final currentUsers = room.currentUsers;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.name!, style: theme.textTheme.headlineLarge),
                        SizedBox(
                          height: 600,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 20,
                            children: [
                              Expanded(child: VotingStory(roomId: widget.roomId!, userName: _username!, cards: room.cardsToUse, story: currentStory)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 50,
                                    width: 400,
                                    decoration: BoxDecoration(color: Colors.blueAccent),
                                    alignment: Alignment.center,
                                    child: Text(currentMessage, style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white)),
                                  ),
                                  if (firebaseUser != null)
                                    Container(
                                      height: 70,
                                      width: 400,
                                      decoration: BoxDecoration(color: Colors.grey[100], border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                                      alignment: Alignment.center,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                          elevation: 5,
                                        ),
                                        onPressed: currentStory.value != null ? () {} : null,
                                        child: Text('Start'),
                                      ),
                                    ),
                                  Container(
                                    height: 50,
                                    width: 400,
                                    decoration: BoxDecoration(color: Colors.grey[100], border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Players:', style: theme.textTheme.headlineSmall),
                                  ),
                                  if (currentUsers != null && currentUsers.isNotEmpty)
                                    ...currentUsers.map(
                                      (u) => Container(
                                        height: 50,
                                        width: 400,
                                        decoration: BoxDecoration(color: Colors.grey[100], border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(u, style: theme.textTheme.bodyLarge),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      //Column(children: [Expanded(child: TextField(decoration: InputDecoration(labelText: 'Jira Issue Key'))), Expanded(child: VoteBoard()), VotingCards()]),
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