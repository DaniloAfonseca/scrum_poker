import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/voting/list/voting_list_tab.dart';
import 'package:web/web.dart' as web;

class VotingList extends StatelessWidget {
  final Room room;
  const VotingList({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('stories').snapshots(),
      builder: (context, snapshot) {
        final maps = snapshot.data?.docs.map((t) => t.data());
        final stories = maps?.map((t) => Story.fromJson(t)).toList() ?? <Story>[];
        stories.sortBy((t) => t.order);

        final currentStory = stories.firstWhereOrNull((t) => t.currentStory);

        final addNewStoryLink = Hyperlink(
          text: 'Add new story',
          textStyle: theme.textTheme.bodyLarge,
          url: currentStory == null ? null : '${web.window.location.protocol}//${web.window.location.host}/editRoom/${currentStory.roomId}',
        );

        return mediaQuery.size.width > 1000
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    VotingListTab(room: room, stories: stories),

                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(padding: const EdgeInsets.all(12.0), child: addNewStoryLink),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 10,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [addNewStoryLink]),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: VotingListTab(room: room, stories: stories),
                  ),
                ],
              );
      },
    );
  }
}
