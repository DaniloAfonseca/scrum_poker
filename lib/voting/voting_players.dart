import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:web/web.dart' as web;
import 'package:scrum_poker/shared/models/app_user.dart';

class VotingPlayers extends StatelessWidget {
  final ValueNotifier<String> currentMessage;
  final ValueNotifier<Story?> currentStory;
  final ValueNotifier<List<AppUser>> currentUsers;
  const VotingPlayers({super.key, required this.currentMessage, required this.currentStory, required this.currentUsers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return ValueListenableBuilder(
      valueListenable: currentUsers,
      builder: (context, currentUsersValue, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
              alignment: Alignment.center,
              child: ValueListenableBuilder(
                valueListenable: currentMessage,
                builder: (context, value, _) {
                  return Text(value, style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white));
                }
              ),
            ),
            if (firebaseUser != null)
              Container(
                height: 70,
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                ),
                alignment: Alignment.center,
                child: ValueListenableBuilder(
                  valueListenable: currentStory,
                  builder: (context, value, _) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        elevation: 5,
                      ),
                      onPressed: value != null ? () {} : null,
                      child: Text('Start'),
                    );
                  }
                ),
              ),
            Container(
              height: 50,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
              ),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Players:', style: theme.textTheme.headlineSmall),
            ),
            if (currentUsersValue.isNotEmpty)
              ...currentUsersValue.mapIndexed(
                (index, u) => Container(
                  height: 50,
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                    borderRadius:
                        index == currentUsersValue.length - 1 && firebaseUser == null ? BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)) : null,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(spacing: 5, children: [Icon(Icons.person, color: u.moderator ? Colors.blueAccent : Colors.black), Text(u.name, style: theme.textTheme.bodyLarge)]),
                ),
              ),
            if (firebaseUser != null)
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.all(0),
                    title: Text('Invite a teammate:', style: theme.textTheme.headlineSmall),
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(web.window.location.href, overflow: TextOverflow.ellipsis)),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: web.window.location.href));
                            },
                            icon: Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
    );
  }
}
