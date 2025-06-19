import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/app_user.dart';

class VotingPlayer extends StatefulWidget {
  final AppUser appUser;
  final AppUser currentAppUser;
  final Function() onObserverChanged;
  final Function() onUserRemoved;
  final Function() onUserRenamed;
  const VotingPlayer({super.key, required this.appUser, required this.currentAppUser, required this.onObserverChanged, required this.onUserRemoved, required this.onUserRenamed});

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
    return Row(
      spacing: 5,
      children: [
        Tooltip(
          message:
              widget.appUser.moderator
                  ? widget.appUser.observer
                      ? 'Moderator observing'
                      : 'Moderator'
                  : widget.appUser.observer
                  ? 'Observer'
                  : '',
          child: IconButton(
            key: _menuKey,
            icon: Icon(
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
                    child: Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Icon(Icons.remove_red_eye_outlined, color: Colors.blueAccent), Text('Observer')],
                    ),
                  ),
                  if (!widget.appUser.moderator) ...[
                    PopupMenuItem(height: 1, enabled: false, child: Divider()),
                    PopupMenuItem(
                      onTap: widget.onUserRemoved,
                      child: Row(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.delete_outline, color: Colors.red), Text('Remove')]),
                    ),
                  ],
                ],
                position: RelativeRect.fromLTRB(position.dx, position.dy + 40, position.dx, position.dy),
              );
            },
          ),
        ),
        Text(widget.appUser.name, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
