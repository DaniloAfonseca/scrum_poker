import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';

class VotingStory extends StatelessWidget {
  final String roomId;
  final String userName;
  final List<VoteEnum> cards;
  final ValueNotifier<Story?> story;

  const VotingStory({super.key, required this.roomId, required this.userName, required this.story, required this.cards});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder:
          (ctx, constraint) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(story.value?.description ?? '', style: theme.textTheme.headlineMedium),
              Container(
                width: constraint.maxWidth,
                height: constraint.maxHeight - 46,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                decoration: BoxDecoration(border: Border.all(width: 6, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
                child:
                    story.value == null || (firebaseUser == null && story.value?.status == StoryStatusEnum.newStory)
                        ? Center(child: Text('Waiting', style: theme.textTheme.displayLarge))
                        : Wrap(
                          spacing: 10,
                          children:
                              cards
                                  .map(
                                    (e) => InkWell(
                                      onTap: story.value?.status == StoryStatusEnum.newStory ? null : () => vote(context, e),
                                      child: Container(
                                        height: 200,
                                        width: 100,
                                        decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6)),
                                        child: Center(
                                          child: Text(
                                            e.label,
                                            style: theme.textTheme.displayLarge!.copyWith(color: story.value?.status == StoryStatusEnum.newStory ? Colors.grey : Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
              ),
            ],
          ),
    );
  }

  void vote(BuildContext context, VoteEnum vote) async {
    // final roomId = 'testRoom';
    // final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    // await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('votes').doc(userId).set({'value': value});
  }
}
