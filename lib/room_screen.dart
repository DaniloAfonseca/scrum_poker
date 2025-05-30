import 'package:flutter/material.dart';
import 'package:scrum_poker/vote_board.dart';
import 'package:scrum_poker/voting_cards.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scrum Poker')),
      body: Column(children: [TextField(decoration: InputDecoration(labelText: 'Jira Issue Key')), Expanded(child: VoteBoard()), VotingCards()]),
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