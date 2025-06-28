import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/app_user.dart';

class VotingPlayer extends StatefulWidget {
  final AppUser appUser;
  final AppUser currentAppUser;
  final bool hasVoted;
  final FutureOr<void> Function() onObserverChanged;
  final FutureOr<void> Function() onUserRemoved;
  final FutureOr<void> Function() onUserRenamed;
  const VotingPlayer({
    super.key,
    required this.appUser,
    required this.currentAppUser,
    this.hasVoted = false,
    required this.onObserverChanged,
    required this.onUserRemoved,
    required this.onUserRenamed,
  });

  @override
  State<VotingPlayer> createState() => _VotingPlayerState();
}

class _VotingPlayerState extends State<VotingPlayer> {
  final _menuKey = GlobalKey();

  void changeUserStatus(bool isObserver) {
    widget.appUser.observer = isObserver;
    setState(() {});
    widget.onObserverChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.only(left: 20),
      leading: Tooltip(
        message:
            widget.appUser.moderator
                ? widget.appUser.observer
                    ? 'Moderator observing'
                    : 'Moderator'
                : widget.appUser.observer
                ? 'Observer'
                : '',
        child: Icon(
          Icons.person,
          color:
              widget.appUser.moderator
                  ? widget.appUser.observer
                      ? Colors.blueAccent[100]
                      : Colors.blueAccent
                  : widget.appUser.observer
                  ? Colors.grey
                  : Colors.black,
        ),
      ),
      title: Row(spacing: 5, children: [Text(widget.appUser.name, style: theme.textTheme.bodyLarge), if (widget.hasVoted) Icon(Icons.check)]),
      trailing: IconButton(
        key: _menuKey,
        icon: Icon(Icons.more_vert),
        onPressed: () {
          RenderBox box = _menuKey.currentContext!.findRenderObject() as RenderBox;
          Offset position = box.localToGlobal(Offset.zero);
          showMenu(
            context: context,
            items: [
              if (widget.appUser.id == widget.currentAppUser.id)
                PopupMenuItem(
                  onTap: widget.onUserRenamed,
                  child: Row(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.edit, color: Colors.blueAccent), Text('Rename')]),
                ),
              PopupMenuItem<bool>(
                value: !widget.appUser.observer,
                enabled: widget.appUser.observer,
                onTap: !widget.appUser.observer ? null : () => changeUserStatus(false),
                child: Row(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.play_arrow, color: Colors.blueAccent), Text('Player')]),
              ),
              PopupMenuItem<bool>(
                value: widget.appUser.observer,
                enabled: !widget.appUser.observer,
                onTap: widget.appUser.observer ? null : () => changeUserStatus(true),
                child: Row(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.remove_red_eye_outlined, color: Colors.blueAccent), Text('Observer')]),
              ),
              if (!widget.appUser.moderator) ...[
                PopupMenuItem(height: 1, enabled: false, child: Divider()),
                PopupMenuItem(
                  onTap: widget.onUserRemoved,
                  child: Row(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.delete_outline, color: Colors.red), Text('Remove')]),
                ),
              ],
            ],
            position: RelativeRect.fromLTRB(position.dx - 105, position.dy, position.dx, position.dy),
          );
        },
      ),
    );
  }
}
