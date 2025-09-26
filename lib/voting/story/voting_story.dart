import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/voting/story/voting_results.dart';
import 'package:scrum_poker/voting/story/voting_story_cards.dart';

class VotingStory extends StatefulWidget {
  final AppUser? appUser;
  final String roomId;
  final bool showStoryDescription;

  const VotingStory({super.key, required this.appUser, required this.roomId, this.showStoryDescription = true});

  @override
  State<VotingStory> createState() => _VotingStoryState();
}

class _VotingStoryState extends State<VotingStory> {
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  if (currentStory?.url == null && widget.showStoryDescription) Text(currentStory?.fullDescription ?? '', style: theme.textTheme.headlineMedium),
                  if (currentStory?.url != null && widget.showStoryDescription)
                    Hyperlink(text: currentStory?.fullDescription ?? '', textStyle: theme.textTheme.headlineMedium!, url: currentStory!.url!),
                  Container(
                    width: constraint.maxWidth,
                    constraints: widget.showStoryDescription ? const BoxConstraints(minHeight: 420) : null,

                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('stories').doc(currentStory?.id ?? '-1').collection('votes').snapshots(),
                      builder: (context, snapshot) {
                        final maps = snapshot.data?.docs.map((t) => t.data());
                        final votes = maps?.map((t) => Vote.fromJson(t)).toList() ?? <Vote>[];
                        final userVote = votes.firstWhereOrNull((t) => t.userId == widget.appUser?.id);

                        return currentStory == null || (user == null && currentStory.status == StoryStatus.notStarted)
                            ? VotingStoryCards(
                                userVote: userVote,
                                cardsToUse: room.cardsToUse,
                                currentStory: currentStory,
                                votes: votes,
                                appUser: widget.appUser,
                                flipCards: ValueNotifier<bool>(currentStory == null ? false : currentStory.status != StoryStatus.notStarted),
                              )
                            : currentStory.status == StoryStatus.voted
                            ? VotingResults(currentStory: currentStory, votes: votes)
                            : VotingStoryCards(
                                userVote: userVote,
                                cardsToUse: room.cardsToUse,
                                currentStory: currentStory,
                                votes: votes,
                                appUser: widget.appUser,
                                flipCards: ValueNotifier<bool>(currentStory.status != StoryStatus.notStarted),
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
