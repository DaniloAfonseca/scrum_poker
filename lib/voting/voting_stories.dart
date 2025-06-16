import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';

class VotingStories extends StatefulWidget {
  final Room room;
  const VotingStories({super.key, required this.room});

  @override
  State<VotingStories> createState() => _VotingStoriesState();
}

class _VotingStoriesState extends State<VotingStories> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStories = widget.room.stories.where((t) => [StatusEnum.notStarted, StatusEnum.started].contains(t.status)).toList();
    final completedStories = widget.room.stories.where((t) => t.status == StatusEnum.ended).toList();
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
                      child: Text(widget.room.stories.length.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: widget.room.stories.length * 50 + 101,
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                Column(
                  children:
                      activeStories
                          .map(
                            (t) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    alignment: Alignment.centerLeft,
                                    height: 50,
                                    child: Text(t.description),
                                  ),
                                ),
                                IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
                              ],
                            ),
                          )
                          .toList(),
                ),
                Column(
                  children:
                      completedStories
                          .map(
                            (t) => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), alignment: Alignment.centerLeft, height: 50, child: Text(t.description)),
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
                    ...widget.room.stories.map(
                      (t) => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), alignment: Alignment.centerLeft, height: 50, child: Text(t.description)),
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
