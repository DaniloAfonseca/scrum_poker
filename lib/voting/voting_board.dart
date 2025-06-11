import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VotingBoard extends StatelessWidget {
  const VotingBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final roomId = 'testRoom';
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('votes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView(children: docs.map((doc) => ListTile(title: Text('User: ${doc.id}, Vote: ${doc['value']}'))).toList());
      },
    );
  }
}
