import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/user_room.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/text_tag.dart';

class MainPageRoom extends StatefulWidget {
  final UserRoom userRoom;
  final Function() deletedChanged;
  const MainPageRoom({super.key, required this.userRoom, required this.deletedChanged});

  @override
  State<MainPageRoom> createState() => _MainPageRoomState();
}

class _MainPageRoomState extends State<MainPageRoom> {
  final _menuKey = GlobalKey();
  final _user = FirebaseAuth.instance.currentUser;
  late UserRoom _userRoom;

  @override
  void initState() {
    _userRoom = widget.userRoom;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraint) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      Text(
                        _userRoom.name,
                        style: constraint.maxWidth > 900
                            ? theme.textTheme.headlineLarge!.copyWith(color: Colors.white)
                            : theme.textTheme.headlineMedium!.copyWith(color: Colors.white),
                      ),
                      if (_userRoom.dateDeleted != null)
                        TextTag(
                          text: 'DELETED',
                          backgroundColor: Colors.red,
                          foreColor: Colors.white,
                          display: _userRoom.dateDeleted != null,
                          toolTipText: _userRoom.dateDeleted != null ? 'Delete on ${DateFormat('yyyy-MM-dd - kk:mm').format(_userRoom.dateDeleted!)}' : null,
                        ),
                      if (_userRoom.status == RoomStatus.started)
                        TextTag(text: 'STARTED', backgroundColor: Colors.green, foreColor: Colors.white, display: _userRoom.status == RoomStatus.started),
                      if (_userRoom.status == RoomStatus.ended)
                        TextTag(text: 'CLOSED', backgroundColor: Colors.white, foreColor: Colors.red, display: _userRoom.status == RoomStatus.ended),
                    ],
                  ),
                  Text('Added on ${DateFormat('yyyy-MM-dd - kk:mm').format(_userRoom.dateAdded!)}', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
                  SizedBox(
                    width: constraint.maxWidth - 80,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Text('Total number of stories: ${_userRoom.allStories ?? 0},', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
                        Text('Active stories: ${_userRoom.activeStories ?? 0},', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
                        Text('Skipped stories: ${_userRoom.skippedStories ?? 0},', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
                        Text('Completed stories: ${_userRoom.completedStories ?? 0}', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),

              IconButton(
                key: _menuKey,
                onPressed: () {
                  RenderBox box = _menuKey.currentContext!.findRenderObject() as RenderBox;
                  Offset position = box.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    items: [
                      PopupMenuItem(
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.edit, color: Colors.blueAccent),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          context.go(Routes.editRoom, extra: _userRoom.roomId);
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.play_arrow_outlined, color: Colors.blueAccent),
                            Text('Open'),
                          ],
                        ),
                        onTap: () async {
                          context.go('${Routes.room}/${_userRoom.roomId}');
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            Text('Delete'),
                          ],
                        ),
                        onTap: () async {
                          _userRoom.dateDeleted = DateTime.now();
                          final json = _userRoom.toJson();
                          await FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('rooms').doc(_userRoom.roomId).set(json);
                          final dbRoom = await FirebaseFirestore.instance.collection('rooms').doc(_userRoom.roomId).snapshots().first;

                          final room = Room.fromJson(dbRoom.data()!);
                          room.dateDeleted = _userRoom.dateDeleted;
                          final roomMap = room.toJson();
                          await FirebaseFirestore.instance.collection('rooms').doc(_userRoom.roomId).set(roomMap);

                          widget.deletedChanged();
                        },
                      ),
                    ],
                    position: RelativeRect.fromLTRB(position.dx - 110, position.dy, position.dx, position.dy),
                  );
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
