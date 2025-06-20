import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/voting/voting_story_item.dart';

class VotingStoryList extends StatefulWidget {
  final String roomId;
  const VotingStoryList({super.key, required this.roomId});

  @override
  State<VotingStoryList> createState() => _VotingStoryListState();
}

class _VotingStoryListState extends State<VotingStoryList> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> removeStory(Room room, Story story) async {
    final canDelete = await showConfirm('Delete story', 'You are about to delete story "${story.description}".\nAre you sure?');

    if (canDelete) {
      await room_services.removeStory(room, story);
    }
  }

  Future<bool> showConfirm(String title, String message) async {
    var result = false;
    await showDialog(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                result = true;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                elevation: 5,
              ),
              child: const Text('Yes'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                result = false;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                elevation: 5,
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> skipStory(Room room, Story story) async {
    if (room.currentStory?.status == StatusEnum.started) {
      final canSkip = await showConfirm('Move story to active', 'You are about to skip story "${story.description}" that was started, this will remove the votes.\nAre you sure?');
      if (!canSkip) {
        return;
      }
    }

    await room_services.skipStory(room, story);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final map = snapshot.data!.data()!;
        final room = Room.fromJson(map);
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
                                  currentStory: room.currentStory,
                                  onDelete: () => removeStory(room, t),
                                  story: t,
                                  onMoveDown: index < activeStories.length - 1 ? () => room_services.moveStoryDown(room, index, t) : null,
                                  onMoveUp: index == 0 ? null : () => room_services.moveStoryUp(room, index, t),
                                  onSkip: () => skipStory(room, t),
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
                          (t) =>
                              VotingStoryItem(currentStory: room.currentStory, story: t, onMoveToActive: t.status == StatusEnum.skipped ? () => room_services.moveStoryToActive(room, t) : null),
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
                          (t) =>
                              VotingStoryItem(currentStory: room.currentStory, story: t, onMoveToActive: t.status == StatusEnum.skipped ? () => room_services.moveStoryToActive(room, t) : null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
