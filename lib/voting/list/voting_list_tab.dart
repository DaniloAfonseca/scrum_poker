import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/voting/list/voting_list_item.dart';

class VotingListTab extends StatefulWidget {
  final Room room;
  final List<Story> stories;
  const VotingListTab({super.key, required this.room, required this.stories});

  @override
  State<VotingListTab> createState() => _VotingListTabState();
}

class _VotingListTabState extends State<VotingListTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _isReordering = ValueNotifier<bool>(false);

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

  Future<void> removeStory(List<Story> stories, Story story) async {
    final canDelete = await showConfirm('Delete story', 'You are about to delete story "${story.description}".\nAre you sure?');

    if (canDelete) {
      await room_services.removeStory(stories, story);
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
            const SizedBox(width: 10),
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

  Future<void> skipStory(Room room, List<Story> stories, Story story, [Story? currentStory]) async {
    if (story.status == StoryStatus.started) {
      final canSkip = await showConfirm('Move story to active', 'You are about to skip story "${story.description}" that was started, this will remove the votes.\nAre you sure?');
      if (!canSkip) {
        return;
      }
    }

    await room_services.skipStory(story);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;

    final activeStories = widget.stories.where((t) => [StoryStatus.notStarted, StoryStatus.started, StoryStatus.voted].contains(t.status)).toList();
    final completedStories = widget.stories.where((t) => [StoryStatus.skipped, StoryStatus.ended].contains(t.status)).toList();

    final currentStory = widget.stories.firstWhereOrNull((t) => t.currentStory);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          labelPadding: const EdgeInsets.all(0),
          tabs: [
            Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  spacing: 10,
                  children: [
                    Text('Active Stories', style: isLarge ? theme.textTheme.titleLarge : theme.textTheme.titleMedium),
                    CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      radius: isLarge ? 12 : 9,
                      child: Text(
                        activeStories.length.toString(),
                        style: isLarge ? theme.textTheme.bodyMedium!.copyWith(color: Colors.white) : theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  spacing: 10,
                  children: [
                    Text('Completed Stories', style: isLarge ? theme.textTheme.titleLarge : theme.textTheme.titleMedium),
                    CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      radius: isLarge ? 12 : 9,
                      child: Text(
                        completedStories.length.toString(),
                        style: isLarge ? theme.textTheme.bodyMedium!.copyWith(color: Colors.white) : theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  spacing: 10,
                  children: [
                    Text('All Stories', style: isLarge ? theme.textTheme.titleLarge : theme.textTheme.titleMedium),
                    CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      radius: isLarge ? 12 : 9,
                      child: Text(
                        widget.stories.length.toString(),
                        style: isLarge ? theme.textTheme.bodyMedium!.copyWith(color: Colors.white) : theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey[300]!),
        SizedBox(
          height: widget.stories.length * 50 + 100,
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              ReorderableListView.builder(
                buildDefaultDragHandles: false,
                onReorderStart: (index) {
                  _isReordering.value = true;
                },
                onReorderEnd: (index) {
                  _isReordering.value = false;
                },
                itemBuilder: (context, index) {
                  final t = activeStories[index];
                  return VotingListItem(
                    key: Key('$index'),
                    currentStory: currentStory,
                    onDelete: () => removeStory(widget.stories, t),
                    story: t,
                    onMoveDown: index < activeStories.length - 1 ? () => room_services.moveStoryDown(widget.stories, t) : null,
                    onMoveUp: index == 0 ? null : () => room_services.moveStoryUp(widget.stories, t),
                    onSkip: () => skipStory(widget.room, widget.stories, t, currentStory),
                    reorderIndex: index,
                    isReordering: _isReordering,
                  );
                },
                itemCount: activeStories.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  room_services.swapStories(widget.stories, oldIndex, newIndex);
                },
              ),
              Column(
                children: completedStories
                    .map(
                      (t) => VotingListItem(
                        currentStory: currentStory,
                        story: t,
                        onMoveToActive: t.status == StoryStatus.skipped ? () => room_services.moveStoryToActive(widget.stories, t) : null,
                      ),
                    )
                    .toList(),
              ),
              ReorderableListView.builder(
                buildDefaultDragHandles: false,
                onReorderStart: (index) {
                  _isReordering.value = true;
                },
                onReorderEnd: (index) {
                  _isReordering.value = false;
                },
                itemBuilder: (context, index) {
                  final t = widget.stories[index];
                  return VotingListItem(
                    key: Key('$index'),
                    currentStory: currentStory,
                    story: t,
                    onMoveToActive: t.status == StoryStatus.skipped ? () => room_services.moveStoryToActive(widget.stories, t) : null,
                    reorderIndex: index,
                    isReordering: _isReordering,
                  );
                },
                itemCount: widget.stories.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  room_services.swapStories(widget.stories, oldIndex, newIndex);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
