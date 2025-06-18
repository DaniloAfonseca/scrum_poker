import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/voting/voting_story_item.dart';

class VotingStoryList extends StatefulWidget {
  final Room room;
  final ValueNotifier<Story?> currentStory;
  const VotingStoryList({super.key, required this.room, required this.currentStory});

  @override
  State<VotingStoryList> createState() => _VotingStoryListState();
}

class _VotingStoryListState extends State<VotingStoryList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Room room;

  @override
  void initState() {
    room = widget.room;
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> saveRoom() async {
    final roomMap = room.toJson();
    await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(roomMap);
  }

  void moveStoryUp(Story story) {
    
  }

  void moveStoryDown(Story story) {}

  void deleteStory(Story story) {}

  void skipStory(Story story) {
    story.status = StatusEnum.skipped;
    saveRoom();
  }

  void moveToActive(Story story) {
    story.status = StatusEnum.notStarted;
    saveRoom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStories = room.stories.where((t) => [StatusEnum.notStarted, StatusEnum.started].contains(t.status)).toList();
    final completedStories = room.stories.where((t) => [StatusEnum.skipped, StatusEnum.ended].contains(t.status)).toList();
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: [
              Tab(
                child: Row(
                  spacing: 10,
                  children: [
                    Text('Active Stories', style: theme.textTheme.titleLarge),
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 15,
                      child: Text(activeStories.length.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  spacing: 10,
                  children: [
                    Text('Completed Stories', style: theme.textTheme.titleLarge),
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 15,
                      child: Text(completedStories.length.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  spacing: 10,
                  children: [
                    Text('All Stories', style: theme.textTheme.titleLarge),
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 15,
                      child: Text(room.stories.length.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: room.stories.length * 50 + 101,
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                Column(
                  children:
                      activeStories
                          .mapIndexed(
                            (index, t) => VotingStoryItem(
                              currentStory: widget.currentStory,
                              onDelete: () {},
                              story: t,
                              onMoveDown: index < activeStories.length - 1 ? () => moveStoryDown(t) : null,
                              onMoveUp: index == 0 ? null : () => moveStoryUp(t),
                              onSkip: () => skipStory(t) ,
                            ),
                          )
                          .toList(),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Padding(padding: const EdgeInsets.only(left: 16.0), child: Text('Title', style: theme.textTheme.headlineSmall))),
                        SizedBox(width: 120, child: Text('Calc. Est.', style: theme.textTheme.headlineSmall)),
                        Container(padding: EdgeInsets.only(right: 16), width: 136, child: Text('Real Est.', style: theme.textTheme.headlineSmall)),
                      ],
                    ),
                    ...completedStories.map(
                      (t) => VotingStoryItem(
                        currentStory: widget.currentStory,
                        story: t,
                        onMoveToActive:
                            t.status == StatusEnum.skipped
                                ? () => moveToActive(t) 
                                : null,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Padding(padding: const EdgeInsets.only(left: 16.0), child: Text('Title', style: theme.textTheme.headlineSmall))),
                        SizedBox(width: 120, child: Text('Calc. Est.', style: theme.textTheme.headlineSmall)),
                        Container(padding: EdgeInsets.only(right: 16), width: 136, child: Text('Real Est.', style: theme.textTheme.headlineSmall)),
                      ],
                    ),
                    ...room.stories.map(
                      (t) => VotingStoryItem(
                        currentStory: widget.currentStory,
                        story: t,
                        onMoveToActive:
                            t.status == StatusEnum.skipped
                                ? () => moveToActive(t) 
                                : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
