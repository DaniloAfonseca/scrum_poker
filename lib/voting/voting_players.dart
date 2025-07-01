import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/voting/voting_player.dart';
import 'package:web/web.dart' as web;
import 'package:scrum_poker/shared/models/app_user.dart';

class VotingPlayers extends StatelessWidget {
  final String roomId;
  final RoomStatus roomStatus;
  final FutureOr<void> Function(AppUser appUser) onUserRenamed;
  final AppUser appUser;
  const VotingPlayers({super.key, required this.roomStatus, required this.roomId, required this.appUser, required this.onUserRenamed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').snapshots(),
      builder: (context, snapshot) {
        final maps = snapshot.data?.docs.map((t) => t.data());
        final stories = maps?.map((t) => Story.fromJson(t)).toList() ?? <Story>[];
        final currentStory = stories.firstWhereOrNull((t) => t.currentStory);

        return StreamBuilder(
          stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('currentUsers').snapshots(),
          builder: (context, snapshot) {
            final maps = snapshot.data?.docs.map((t) => t.data());
            final currentUsers = maps?.map((t) => AppUser.fromJson(t)).toList();

            final numPlayers = currentUsers?.where((t) => !t.observer).length ?? 0;

            return StreamBuilder(
              stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(currentStory?.id ?? '').collection('votes').snapshots(),
              builder: (context, snapshot) {
                final maps = snapshot.data?.docs.map((t) => t.data());
                final votes = maps?.map((t) => Vote.fromJson(t)).toList() ?? <Vote>[];

                final numPlayersWhoVoted = votes.length;
                final notVoted = numPlayers - numPlayersWhoVoted;

                final currentMessage =
                    currentStory == null
                        ? 'Waiting'
                        : currentStory.status == StoryStatus.voted
                        ? 'Story voting completed'
                        : currentStory.status == StoryStatus.notStarted
                        ? firebaseUser != null
                            ? 'Click "Start" to begin voting'
                            : 'Waiting for moderator'
                        : notVoted == 0
                        ? firebaseUser != null
                            ? 'All players have voted'
                            : 'Waiting for moderator'
                        : 'Waiting for $notVoted players to vote';

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
                      child: Text(currentMessage, style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white)),
                    ),
                    if (firebaseUser != null && roomStatus != RoomStatus.ended)
                      Container(
                        height: 95,
                        width: 400,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                        ),
                        alignment: Alignment.center,
                        child:
                            currentStory?.status == StoryStatus.notStarted
                                ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                    elevation: 5,
                                  ),
                                  onPressed: currentStory != null ? () => room_services.storyStart(roomId, roomStatus, stories, currentStory, appUser.id!) : null,
                                  child: Text('Start'),
                                )
                                : currentStory?.status == StoryStatus.voted
                                ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                    elevation: 5,
                                  ),
                                  onPressed: currentStory != null ? () => room_services.nextStory(roomId, roomStatus, stories, currentStory, appUser.id!) : null,
                                  child: Text('Next story'),
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      spacing: 10,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                            elevation: 5,
                                          ),
                                          onPressed: currentStory != null ? () => room_services.flipCards(roomId, roomStatus, stories, currentStory, appUser.id!, votes) : null,
                                          child: Text('Flip cards'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                            elevation: 5,
                                          ),
                                          onPressed: currentStory != null ? () => room_services.clearStoryVotes(roomId, currentStory) : null,
                                          child: Text('Clear votes'),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                        elevation: 5,
                                      ),
                                      onPressed: currentStory != null ? () => room_services.skipStory(roomId, roomStatus, stories, currentStory, appUser.id!) : null,
                                      child: Text('Skip story'),
                                    ),
                                  ],
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
                    if (currentUsers != null && (currentUsers.isNotEmpty))
                      ...currentUsers.mapIndexed(
                        (index, u) => Container(
                          height: 50,
                          width: 400,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                            borderRadius:
                                index == currentUsers.length - 1 && firebaseUser == null
                                    ? BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6))
                                    : null,
                          ),
                          alignment: Alignment.centerLeft,
                          child: VotingPlayer(
                            hasVoted: votes.any((t) => t.userId == u.id),
                            currentAppUser: appUser,
                            appUser: u,
                            onObserverChanged: () => room_services.updateCurrentUser(roomId, u.id!, {'observer': u.observer}),
                            onUserRemoved: () => room_services.removeUser(roomId, u.id!),
                            onUserRenamed: () => onUserRenamed(u),
                          ),
                        ),
                      ),
                    if (appUser.moderator)
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
              },
            );
          },
        );
      },
    );
  }
}
