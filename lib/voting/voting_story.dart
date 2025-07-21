import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:scrum_poker/voting/voting_pie_chart.dart';

class VotingStory extends StatefulWidget {
  final AppUser? appUser;
  final String roomId;
  final FutureOr<void> Function(List<Vote> votes) votesChanged;

  const VotingStory({super.key, required this.appUser, required this.roomId, required this.votesChanged});

  @override
  State<VotingStory> createState() => _VotingStoryState();
}

class _VotingStoryState extends State<VotingStory> {
  String? _storyPointFieldName;
  final _formKey = GlobalKey<FormState>();
  final storyPointController = TextEditingController();

  @override
  void initState() {
    _storyPointFieldName = SettingsManager().storyPointFieldName;
    super.initState();
  }

  Future<void> vote(String roomId, Story story, List<Vote> votes, VoteEnum vote) async {
    if (widget.appUser == null) {
      return;
    }
    var localUserVote = votes.firstWhereOrNull((t) => t.userId == widget.appUser!.id);
    if (localUserVote == null) {
      localUserVote = Vote(userId: widget.appUser!.id, value: vote, userName: widget.appUser!.name, roomId: roomId, storyId: story.id, storyStatus: story.status);
      votes.add(localUserVote);
    } else {
      localUserVote.value = vote;
    }
    widget.votesChanged(votes);
    await room_services.updateVote(localUserVote);
  }

  Future<void> updateStoryPoint(Story story) async {
    if (_formKey.currentState!.validate()) {
      story.revisedEstimate = double.parse(storyPointController.text);
      await room_services.updateRevisedEstimate(story);
      final response = await JiraServices().updateStoryPoints(story.jiraKey!, _storyPointFieldName!, story.revisedEstimate!);
      if (!response.success) {
        snackbarMessenger(navigatorKey.currentContext!, message: response.message!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (ctx, constraint) => StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final map = snapshot.data!.data()!;
          final room = Room.fromJson(map);

          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('stories').snapshots(),
            builder: (context, snapshot) {
              final maps = snapshot.data?.docs.map((t) => t.data());
              final stories = maps?.map((t) => Story.fromJson(t)).toList() ?? <Story>[];
              final currentStory = stories.firstWhereOrNull((t) => t.currentStory);
              storyPointController.text = currentStory?.revisedEstimate?.toString() ?? currentStory?.estimate?.toString() ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  if (currentStory?.url == null) Text(currentStory?.fullDescription ?? '', style: theme.textTheme.headlineMedium),
                  if (currentStory?.url != null) Hyperlink(text: currentStory?.fullDescription ?? '', textStyle: theme.textTheme.headlineMedium!, url: currentStory!.url!),
                  Container(
                    width: constraint.maxWidth,
                    constraints: const BoxConstraints(minHeight: 420),
                    decoration: currentStory == null || (user == null && currentStory.status == StoryStatus.notStarted)
                        ? BoxDecoration(
                            border: Border.all(width: 2, color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('stories').doc(currentStory?.id ?? '-1').collection('votes').snapshots(),
                      builder: (context, snapshot) {
                        final maps = snapshot.data?.docs.map((t) => t.data());
                        final votes = maps?.map((t) => Vote.fromJson(t)).toList() ?? <Vote>[];
                        final userVote = votes.firstWhereOrNull((t) => t.userId == widget.appUser?.id);

                        //votesChanged(votes);

                        return currentStory == null || (user == null && currentStory.status == StoryStatus.notStarted)
                            ? Center(child: Text('Waiting', style: theme.textTheme.displayLarge))
                            : currentStory.status == StoryStatus.voted
                            ? Builder(
                                builder: (context) {
                                  return Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 20,
                                        children: [
                                          Expanded(
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 10,
                                              runSpacing: 10,
                                              children: votes
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
                                                              child: e.value.icon != null
                                                                  ? Icon(
                                                                      e.value.icon,
                                                                      size: 48,
                                                                      color: currentStory.status == StoryStatus.notStarted ? Colors.grey : theme.textTheme.displayLarge?.color,
                                                                    )
                                                                  : Text(
                                                                      e.value.label,
                                                                      style: theme.textTheme.displayLarge!.copyWith(
                                                                        color: currentStory.status == StoryStatus.notStarted ? Colors.grey : null,
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
                                            decoration: BoxDecoration(
                                              border: Border.all(width: 2, color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
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
                                      ),
                                      if (user != null && _storyPointFieldName != null && _storyPointFieldName!.isNotEmpty)
                                        Form(
                                          key: _formKey,
                                          child: Row(
                                            spacing: 10,
                                            children: [
                                              SizedBox(
                                                width: 200,
                                                child: TextFormField(
                                                  controller: storyPointController,
                                                  decoration: const InputDecoration(label: Text('Update story points')),
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Please, introduce a value';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: theme.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                  elevation: 5,
                                                ),
                                                onPressed: currentStory.jiraKey == null
                                                    ? null
                                                    : () {
                                                        if (_formKey.currentState!.validate()) {
                                                          updateStoryPoint(currentStory);
                                                        }
                                                      },
                                                child: const Text('Update'),
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
                                children: room.cardsToUse
                                    .map(
                                      (e) => InkWell(
                                        onTap: widget.appUser == null || currentStory.status == StoryStatus.notStarted ? null : () => vote(widget.roomId, currentStory, votes, e),
                                        child: Container(
                                          height: 200,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            color: userVote?.value == e ? Colors.blueAccent[100] : null,
                                            border: Border.all(width: 2, color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Center(
                                            child: e.icon != null
                                                ? Icon(e.icon, size: 48, color: currentStory.status == StoryStatus.notStarted ? Colors.grey : theme.textTheme.displayLarge?.color)
                                                : Text(
                                                    e.label,
                                                    style: theme.textTheme.displayLarge!.copyWith(color: currentStory.status == StoryStatus.notStarted ? Colors.grey : null),
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
