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
  final user = FirebaseAuth.instance.currentUser;
  late UserRoom userRoom;

  @override
  void initState() {
    userRoom = widget.userRoom;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
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
                  Text(userRoom.name, style: theme.textTheme.headlineLarge!.copyWith(color: Colors.white)),
                  TextTag(
                    text: 'DELETED',
                    backgroundColor: Colors.red,
                    foreColor: Colors.white,
                    display: userRoom.dateDeleted != null,
                    toolTipText: userRoom.dateDeleted != null ? 'Delete on ${DateFormat('yyyy-MM-dd - kk:mm').format(userRoom.dateDeleted!)}' : null,
                  ),
                  TextTag(text: 'Started', backgroundColor: Colors.green, foreColor: Colors.white, display: userRoom.status == RoomStatus.started),
                ],
              ),
              Text('Added on ${DateFormat('yyyy-MM-dd - kk:mm').format(userRoom.dateAdded!)}', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
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
                    child: Row(spacing: 5, children: [Icon(Icons.edit, color: Colors.blueAccent), Text('Edit')]),
                    onTap: () {
                      context.go(Routes.editRoom, extra: userRoom.roomId);
                    },
                  ),
                  PopupMenuItem(
                    child: Row(spacing: 5, children: [Icon(Icons.play_arrow_outlined, color: Colors.blueAccent), Text('Open')]),
                    onTap: () async {
                      context.go('${Routes.room}/${userRoom.roomId}');
                    },
                  ),
                  PopupMenuItem(
                    child: Row(spacing: 5, children: [Icon(Icons.delete_outline, color: Colors.red), Text('Delete')]),
                    onTap: () async {
                      userRoom.dateDeleted = DateTime.now();
                      final json = userRoom.toJson();
                      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('rooms').doc(userRoom.roomId).set(json);
                      final dbRoom = await FirebaseFirestore.instance.collection('rooms').doc(userRoom.roomId).snapshots().first;

                      final room = Room.fromJson(dbRoom.data()!);
                      room.dateDeleted = userRoom.dateDeleted;
                      final roomMap = room.toJson();
                      await FirebaseFirestore.instance.collection('rooms').doc(userRoom.roomId).set(roomMap);

                      widget.deletedChanged();
                    },
                  ),
                ],
                position: RelativeRect.fromLTRB(position.dx - 110, position.dy, position.dx, position.dy),
              );
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
