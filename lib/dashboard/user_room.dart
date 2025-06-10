import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:intl/intl.dart';
import 'package:scrum_poker/shared/models/user.dart' as u;
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/text_tag.dart';

class UserRoom extends StatefulWidget {
  final u.User user;
  final Room room;
  final Function() deletedChanged;
  const UserRoom({super.key, required this.user, required this.room, required this.deletedChanged});

  @override
  State<UserRoom> createState() => _UserRoomState();
}

class _UserRoomState extends State<UserRoom> {
  final _menuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.blue[600],
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
                  Text(widget.room.name!, style: theme.textTheme.headlineLarge!.copyWith(color: Colors.white)),
                  TextTag(
                    text: 'DELETED',
                    backgroundColor: Colors.red,
                    foreColor: Colors.white,
                    display: widget.room.dateDeleted != null,
                    toolTipText: widget.room.dateDeleted != null ? 'Delete on ${DateFormat('yyyy-MM-dd - kk:mm').format(widget.room.dateDeleted!)}' : null,
                  ),
                ],
              ),
              Text('Added on ${DateFormat('yyyy-MM-dd - kk:mm').format(widget.room.dateAdded!)}', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white)),
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
                    child: Row(spacing: 5, children: [Icon(Icons.edit), Text('Edit')]),
                    onTap: () {
                      context.go(Routes.editRoom, extra: {'roomId': widget.room.id, 'user': widget.user});
                    },
                  ),
                  PopupMenuItem(
                    child: Row(spacing: 5, children: [Icon(Icons.delete_outline), Text('Delete')]),
                    onTap: () async {
                      widget.room.dateDeleted = DateTime.now();
                      final json = widget.user.toJson();
                      await FirebaseFirestore.instance.collection('users').doc(widget.user.id).set(json);
                      widget.deletedChanged();
                    },
                  ),
                ],
                position: RelativeRect.fromLTRB(position.dx - 60, position.dy + 40, position.dx, position.dy),
              );
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
