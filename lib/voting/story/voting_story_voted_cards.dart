import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/widgets/card.dart';

import '../../shared/widgets/flip_card_animation.dart';

class VotingStoryVotedCards extends StatefulWidget {
  final List<Vote> votes;
  final Story currentStory;
  const VotingStoryVotedCards({super.key, required this.votes, required this.currentStory});

  @override
  State<VotingStoryVotedCards> createState() => _VotingStoryVotedCardsState();
}

class _VotingStoryVotedCardsState extends State<VotingStoryVotedCards> {
  final _isFlipped = ValueNotifier<bool>(false);

  @override
  void initState() {
    setFlip();
    super.initState();
  }

  void setFlip() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(const Duration(seconds: 1), () {
        _isFlipped.value = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;
    return ValueListenableBuilder(
      valueListenable: _isFlipped,
      builder: (context, showAll, child) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: widget.votes
              .map(
                (e) => Column(
                  spacing: 10,
                  children: [
                    FlipCardAnimation(
                      isFlipped: showAll,
                      back: FlipCard(
                        height: isLarge ? 200 : 100,
                        width: isLarge ? 150 : 75,
                        borderColorOutside: Colors.grey[300],
                        isFront: true,
                        child: Center(
                          child: e.value.icon != null
                              ? Icon(
                                  e.value.icon,
                                  size: isLarge ? 48 : 24,
                                  color: widget.currentStory.status == StoryStatus.notStarted ? Colors.grey : theme.textTheme.displayLarge?.color,
                                )
                              : Text(
                                  e.value.label,
                                  style: isLarge
                                      ? theme.textTheme.displayLarge!.copyWith(color: widget.currentStory.status == StoryStatus.notStarted ? Colors.grey : null)
                                      : theme.textTheme.displaySmall!.copyWith(color: widget.currentStory.status == StoryStatus.notStarted ? Colors.grey : null),
                                ),
                        ),
                      ),

                      front: FlipCard(
                        height: isLarge ? 200 : 100,
                        width: isLarge ? 150 : 75,
                        isFront: false,
                        borderColorInside: Colors.grey,
                        borderColorOutside: Colors.grey,
                        child: Center(child: SvgPicture.asset('images/logo_disable_mode.svg', fit: BoxFit.contain, width: 90)),
                      ),
                    ),
                    Text(e.userName),
                  ],
                ),
              )
              .toList(),
        );
      },
    );
  }
}
