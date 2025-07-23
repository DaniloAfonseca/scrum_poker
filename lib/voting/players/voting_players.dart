import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/voting/players/voting_player.dart';
import 'package:web/web.dart' as web;
import 'package:scrum_poker/shared/models/app_user.dart';

class VotingPlayers extends StatelessWidget {
  final Room room;
  final ValueNotifier<Story?> currentStoryVN;
  final FutureOr<void> Function(AppUser appUser) onUserRenamed;
  final AppUser appUser;
  const VotingPlayers({super.key, required this.room, required this.appUser, required this.onUserRenamed, required this.currentStoryVN});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final currentStory = currentStoryVN.value;
    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('stories').doc(currentStory?.id ?? '-1').collection('votes').snapshots(),
      builder: (context, snapshot) {
        final maps = snapshot.data?.docs.map((t) => t.data());
        final votes = maps?.map((t) => Vote.fromJson(t)).toList() ?? <Vote>[];

        return StreamBuilder(
          stream: FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('currentUsers').snapshots(),
          builder: (context, snapshot) {
            final maps = snapshot.data?.docs.map((t) => t.data());
            final currentUsers = maps?.map((t) => AppUser.fromJson(t)).toList();

            final numPlayers = currentUsers?.where((t) => !t.observer).length ?? 0;

            final numPlayersWhoVoted = votes.length;
            final notVoted = numPlayers - numPlayersWhoVoted;

            final currentMessage = currentStory == null
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
                  constraints: const BoxConstraints(minHeight: 50),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currentMessage,
                    style: isLarge ? theme.textTheme.headlineSmall!.copyWith(color: Colors.white) : theme.textTheme.titleLarge!.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (firebaseUser != null && room.status != RoomStatus.ended)
                  Container(
                    constraints: const BoxConstraints(minHeight: 95),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withAlpha(80),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                        left: BorderSide(color: Colors.grey[300]!),
                        right: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: currentStory?.status == StoryStatus.notStarted
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              elevation: 5,
                            ),
                            onPressed: currentStory != null ? () => room_services.storyStart(room, currentStory) : null,
                            child: const Text('Start'),
                          )
                        : currentStory?.status == StoryStatus.voted
                        ? Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,

                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  elevation: 5,
                                ),
                                onPressed: currentStory != null ? () => room_services.nextStory(room, currentStory, votes) : null,
                                child: const Text('Next story'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  elevation: 5,
                                ),
                                onPressed: currentStory != null ? () => room_services.clearStoryVotes(currentStory) : null,
                                child: const Text('Clear votes'),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  elevation: 5,
                                ),
                                onPressed: currentStory != null ? () => room_services.flipCards(room, currentStory, votes) : null,
                                child: const Text('Flip cards'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  elevation: 5,
                                ),
                                onPressed: currentStory != null ? () => room_services.clearStoryVotes(currentStory) : null,
                                child: const Text('Clear votes'),
                              ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  elevation: 5,
                                ),
                                onPressed: currentStory != null ? () => room_services.skipStory(room, currentStory) : null,
                                child: const Text('Skip story'),
                              ),
                            ],
                          ),
                  ),
                Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  decoration: BoxDecoration(
                    color: theme.hoverColor,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                      left: BorderSide(color: Colors.grey[300]!),
                      right: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Players:', style: isLarge ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge),
                ),
                if (currentUsers != null && (currentUsers.isNotEmpty))
                  ...currentUsers.mapIndexed(
                    (index, u) => Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      decoration: BoxDecoration(
                        color: theme.hoverColor,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                          left: BorderSide(color: Colors.grey[300]!),
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                        borderRadius: index == currentUsers.length - 1 && firebaseUser == null
                            ? const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6))
                            : null,
                      ),
                      alignment: Alignment.centerLeft,
                      child: VotingPlayer(
                        hasVoted: votes.any((t) => t.userId == u.id),
                        currentAppUser: appUser,
                        appUser: u,
                        onObserverChanged: () => room_services.updateCurrentUser(room.id, u.id, {'observer': u.observer}),
                        onUserRemoved: () => room_services.removeUser(room.id, u.id),
                        onUserRenamed: () => onUserRenamed(u),
                      ),
                    ),
                  ),
                if (appUser.moderator)
                  Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    decoration: BoxDecoration(
                      color: theme.hoverColor,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                        left: BorderSide(color: Colors.grey[300]!),
                        right: BorderSide(color: Colors.grey[300]!),
                      ),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.all(0),
                        title: Text('Invite a teammate:', style: isLarge ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge),
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(web.window.location.href, overflow: TextOverflow.ellipsis)),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: web.window.location.href));
                                },
                                icon: const Icon(Icons.copy),
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
  }
}
