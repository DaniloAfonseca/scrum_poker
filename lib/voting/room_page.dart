import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/voting/room_login.dart';
import 'package:scrum_poker/voting/vote_board.dart';
import 'package:scrum_poker/voting/voting_cards.dart';

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
  Room? room;

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
      final dbUser = await FirebaseFirestore.instance.collection('users').doc(firebaseUser!.uid).snapshots().first;
      _box!.put('username', dbUser['name']);
    }

    if (_box!.get('username') != null) {}

    setState(() {
      _username = _box!.get('username');
      _isLoading = false;
    });
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
                    //room = await FirebaseFirestore.instance.collection('room').doc(widget.roomId).snapshots().first;
                  });
                },
              )
              : //Column(children: [Text()],)
              Column(children: [Expanded(child: TextField(decoration: InputDecoration(labelText: 'Jira Issue Key'))), Expanded(child: VoteBoard()), VotingCards()]),
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