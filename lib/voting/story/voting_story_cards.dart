import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;

class VotingStoryCards extends StatefulWidget {
  final List<Vote> votes;
  final AppUser? appUser;
  final List<VoteEnum> cardsToUse;
  final Story currentStory;
  final Vote? userVote;
  const VotingStoryCards({super.key, this.appUser, required this.cardsToUse, required this.currentStory, required this.votes, this.userVote});

  @override
  State<VotingStoryCards> createState() => _VotingStoryCardsState();
}

class _VotingStoryCardsState extends State<VotingStoryCards> {
  VoteEnum? _hoveredCard;

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
    await room_services.updateVote(localUserVote);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;
    return Wrap(
      spacing: isLarge ? 10 : 0,
      runSpacing: isLarge ? 10 : 0,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widget.cardsToUse.map((e) {
        final votedCard = widget.userVote?.value == e;
        return InkWell(
          onHover: (value) {
            setState(() {
              _hoveredCard = value ? e : null;
            });
          },
          onTap: widget.appUser == null || widget.currentStory.status == StoryStatus.notStarted
              ? null
              : () => vote(widget.currentStory.roomId, widget.currentStory, widget.votes, e),
          child: AnimatedContainer(
            margin: _hoveredCard == e ? const EdgeInsets.all(0) : const EdgeInsets.all(5),
            duration: const Duration(milliseconds: 200),
            height: _hoveredCard == e
                ? isLarge
                      ? 205
                      : 105
                : isLarge
                ? 200
                : 100,
            width: _hoveredCard == e
                ? isLarge
                      ? 155
                      : 80
                : isLarge
                ? 150
                : 75,
            decoration: BoxDecoration(
              color: votedCard ? Colors.blueAccent[100] : null,
              border: Border.all(width: 2, color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: e.icon != null
                  ? Icon(
                      e.icon,
                      size: isLarge ? 48 : 24,
                      color: widget.currentStory.status == StoryStatus.notStarted
                          ? Colors.grey
                          : _hoveredCard == e
                          ? Colors.blueAccent
                          : theme.textTheme.displayLarge?.color,
                    )
                  : Text(
                      e.label,
                      style: isLarge
                          ? theme.textTheme.displayLarge!.copyWith(
                              color: widget.currentStory.status == StoryStatus.notStarted
                                  ? Colors.grey
                                  : _hoveredCard == e
                                  ? Colors.blueAccent
                                  : null,
                            )
                          : theme.textTheme.displaySmall!.copyWith(
                              color: widget.currentStory.status == StoryStatus.notStarted
                                  ? Colors.grey
                                  : _hoveredCard == e
                                  ? Colors.blueAccent
                                  : null,
                            ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
