import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;

class VotingStoryCards extends StatelessWidget {
  final List<Vote> votes;
  final AppUser? appUser;
  final List<VoteEnum> cardsToUse;
  final Story currentStory;
  final Vote? userVote;
  const VotingStoryCards({super.key, this.appUser, required this.cardsToUse, required this.currentStory, required this.votes, this.userVote});

  Future<void> vote(String roomId, Story story, List<Vote> votes, VoteEnum vote) async {
    if (appUser == null) {
      return;
    }
    var localUserVote = votes.firstWhereOrNull((t) => t.userId == appUser!.id);
    if (localUserVote == null) {
      localUserVote = Vote(userId: appUser!.id, value: vote, userName: appUser!.name, roomId: roomId, storyId: story.id, storyStatus: story.status);
      votes.add(localUserVote);
    } else {
      localUserVote.value = vote;
    }
    await room_services.updateVote(localUserVote);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: cardsToUse
          .map(
            (e) => InkWell(
              onTap: appUser == null || currentStory.status == StoryStatus.notStarted ? null : () => vote(currentStory.roomId, currentStory, votes, e),
              child: Container(
                height: isLarge ? 200 : 100,
                width: isLarge ? 150 : 75,
                decoration: BoxDecoration(
                  color: userVote?.value == e ? Colors.blueAccent[100] : null,
                  border: Border.all(width: 2, color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: e.icon != null
                      ? Icon(e.icon, size: isLarge ? 48 : 24, color: currentStory.status == StoryStatus.notStarted ? Colors.grey : theme.textTheme.displayLarge?.color)
                      : Text(
                          e.label,
                          style: isLarge
                              ? theme.textTheme.displayLarge!.copyWith(color: currentStory.status == StoryStatus.notStarted ? Colors.grey : null)
                              : theme.textTheme.displaySmall!.copyWith(color: currentStory.status == StoryStatus.notStarted ? Colors.grey : null),
                        ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
