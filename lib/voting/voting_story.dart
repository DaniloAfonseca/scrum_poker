import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/voting/voting_pie_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class VotingStory extends StatelessWidget {
  final AppUser? appUser;
  final String roomId;

  const VotingStory({super.key, required this.appUser, required this.roomId});

  Future<void> vote(String roomId, String storyId, List<Vote> votes, VoteEnum vote) async {
    if (appUser == null) {
      return;
    }
    var localUserVote = votes.firstWhereOrNull((t) => t.userId == appUser!.id);
    if (localUserVote == null) {
      localUserVote = Vote(userId: appUser!.id!, value: vote, userName: appUser!.name);
      votes.add(localUserVote);
    } else {
      localUserVote.value = vote;
    }
    await room_services.saveVote(roomId, storyId, localUserVote);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder:
          (ctx, constraint) => StreamBuilder(
            stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              final map = snapshot.data!.data()!;
              final room = Room.fromJson(map);

              return StreamBuilder(
                stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').snapshots(),
                builder: (context, snapshot) {
                  final maps = snapshot.data?.docs.map((t) => t.data());
                  final stories = maps?.map((t) => Story.fromJson(t)).toList() ?? <Story>[];
                  final currentStory = stories.firstWhereOrNull((t) => t.currentStory);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      if (currentStory?.url == null) Text(currentStory?.description ?? '', style: theme.textTheme.headlineMedium),
                      if (currentStory?.url != null)
                        InkWell(
                          onTap: () async {
                            final Uri uri = Uri.parse(currentStory!.url!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              throw 'Could not launch ${currentStory.url!}';
                            }
                          },
                          child: Text(
                            currentStory?.description ?? currentStory?.url ?? '',
                            style: theme.textTheme.headlineMedium!.copyWith(
                              color: Colors.transparent,
                              shadows: [Shadow(color: Colors.black, offset: Offset(0, -3))],
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              decorationThickness: 1,
                              decorationStyle: TextDecorationStyle.solid,
                            ),
                          ),
                        ),

                      Container(
                        width: constraint.maxWidth,
                        constraints: BoxConstraints(minHeight: 420),
                        decoration:
                            currentStory == null || (user == null && currentStory.status == StoryStatus.notStarted)
                                ? BoxDecoration(border: Border.all(width: 2, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6))
                                : null,
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('stories').doc(currentStory?.id ?? '').collection('votes').snapshots(),
                          builder: (context, snapshot) {
                            final maps = snapshot.data?.docs.map((t) => t.data());
                            final votes = maps?.map((t) => Vote.fromJson(t)).toList() ?? <Vote>[];
                            final userVote = votes.firstWhereOrNull((t) => t.userId == appUser?.id);
                            
                            return currentStory == null || (user == null && currentStory.status == StoryStatus.notStarted)
                                ? Center(child: Text('Waiting', style: theme.textTheme.displayLarge))
                                : currentStory.status == StoryStatus.voted
                                ? Builder(
                                  builder: (context) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      spacing: 20,
                                      children: [
                                        Expanded(
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 10,
                                            runSpacing: 10,
                                            children:
                                                votes
                                                    .map(
                                                      (e) => SizedBox(
                                                        height: 230,
                                                        width: 150,
                                                        child: Column(
                                                          spacing: 10,
                                                          children: [
                                                            Container(
                                                              height: 200,
                                                              width: 150,
                                                              decoration: BoxDecoration(
                                                                border: Border.all(width: 2, color: Colors.grey[300]!),
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  e.value.label,
                                                                  style: theme.textTheme.displayLarge!.copyWith(
                                                                    color: currentStory.status == StoryStatus.notStarted ? Colors.grey : Colors.black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Text(e.userName),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ),
                                        Container(
                                          width: 350,
                                          height: 400,
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                          decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6)),
                                          child: Column(
                                            spacing: 10,
                                            children: [
                                              SizedBox(height: 40, child: Text('Results', style: theme.textTheme.headlineMedium)),
                                              Expanded(child: VotingPieChart(results: currentStory.voteResults(votes)!)),
                                              SizedBox(
                                                height: 40,
                                                child: Row(
                                                  spacing: 10,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('${votes.length} Players voted', style: theme.textTheme.headlineSmall),
                                                    Text('Avg: ${currentStory.estimate}', style: theme.textTheme.headlineSmall),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                                : Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children:
                                      room.cardsToUse
                                          .map(
                                            (e) => InkWell(
                                              onTap: appUser == null || currentStory.status == StoryStatus.notStarted ? null : () => vote(roomId, currentStory.id, votes, e),
                                              child: Container(
                                                height: 200,
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  color: userVote?.value == e ? Colors.blueAccent[100] : null,
                                                  border: Border.all(width: 2, color: Colors.grey[300]!),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    e.label,
                                                    style: theme.textTheme.displayLarge!.copyWith(
                                                      color: currentStory.status == StoryStatus.notStarted ? Colors.grey : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
    );
  }
}
