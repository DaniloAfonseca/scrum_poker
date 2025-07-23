import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';

class VotingStoryVotedCards extends StatelessWidget {
  final List<Vote> votes;
  final Story currentStory;
  const VotingStoryVotedCards({super.key, required this.votes, required this.currentStory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: votes
          .map(
            (e) => Column(
              spacing: 10,
              children: [
                Container(
                  height: isLarge ? 200 : 100,
                  width: isLarge ? 150 : 75,
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: e.value.icon != null
                        ? Icon(e.value.icon, size: isLarge ? 48 : 24, color: currentStory.status == StoryStatus.notStarted ? Colors.grey : theme.textTheme.displayLarge?.color)
                        : Text(
                            e.value.label,
                            style: isLarge
                                ? theme.textTheme.displayLarge!.copyWith(color: currentStory.status == StoryStatus.notStarted ? Colors.grey : null)
                                : theme.textTheme.displaySmall!.copyWith(color: currentStory.status == StoryStatus.notStarted ? Colors.grey : null),
                          ),
                  ),
                ),
                Text(e.userName),
              ],
            ),
          )
          .toList(),
    );
  }
}
