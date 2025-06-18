import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';

class VotingStory extends StatelessWidget {
  final String roomId;
  final List<VoteEnum> cards;
  final ValueNotifier<Story?> story;

  const VotingStory({super.key, required this.roomId, required this.story, required this.cards});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder:
          (ctx, constraint) => ValueListenableBuilder<Story?>(
            valueListenable: story,
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(story.value?.description ?? '', style: theme.textTheme.headlineMedium),
                  Container(
                    width: constraint.maxWidth,
                    height: user == null ? 400 : null,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    decoration:
                        user == null || story.value == null ? BoxDecoration(border: Border.all(width: 2, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6)) : null,
                    child:
                        value == null || (user == null && value.status == StatusEnum.notStarted)
                            ? Center(child: Text(value == null ? '' : 'Waiting', style: theme.textTheme.displayLarge))
                            : Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  cards
                                      .map(
                                        (e) => InkWell(
                                          onTap: value.status == StatusEnum.notStarted ? null : () => vote(context, e),
                                          child: Container(
                                            height: 200,
                                            width: 150,
                                            decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6)),
                                            child: Center(
                                              child: Text(
                                                e.label,
                                                style: theme.textTheme.displayLarge!.copyWith(color: value.status == StatusEnum.notStarted ? Colors.grey : Colors.black),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void vote(BuildContext context, VoteEnum vote) async {
    // final roomId = 'testRoom';
    // final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    // await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('votes').doc(userId).set({'value': value});
  }
}
