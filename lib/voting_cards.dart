import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VotingCards extends StatelessWidget {
  final List<int> cards = [1, 2, 3, 5, 8, 13, 21];

  VotingCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(children: cards.map((e) => ElevatedButton(onPressed: () => vote(context, e), child: Text('$e'))).toList());
  }

  void vote(BuildContext context, int value) async {
    final roomId = 'testRoom';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('votes').doc(userId).set({'value': value});
  }
}
