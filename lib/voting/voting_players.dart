import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/voting/voting_player.dart';
import 'package:web/web.dart' as web;
import 'package:scrum_poker/shared/models/app_user.dart';

class VotingPlayers extends StatefulWidget {
  final ValueNotifier<String> currentMessage;
  final ValueNotifier<Story?> currentStory;
  final ValueNotifier<List<AppUser>> currentUsers;
  final Function(AppUser appUser) onUserRemoved;
  final Function(AppUser appUser) onObserverChanged;
  final Function(AppUser appUser) onUserRenamed;
  final Function() onStart;
  final AppUser appUser;
  const VotingPlayers({
    super.key,
    required this.currentMessage,
    required this.currentStory,
    required this.currentUsers,
    required this.appUser,
    required this.onUserRemoved,
    required this.onObserverChanged,
    required this.onUserRenamed,
    required this.onStart,
  });

  @override
  State<VotingPlayers> createState() => _VotingPlayersState();
}

class _VotingPlayersState extends State<VotingPlayers> {
  void start(Story story) {
    story.status = StatusEnum.started;
    widget.onStart();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return ValueListenableBuilder(
      valueListenable: widget.currentUsers,
      builder: (context, currentUsersValue, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
              alignment: Alignment.center,
              child: ValueListenableBuilder(
                valueListenable: widget.currentMessage,
                builder: (context, value, _) {
                  return Text(value, style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white));
                },
              ),
            ),
            if (firebaseUser != null)
              Container(
                height: 95,
                width: 400,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                ),
                alignment: Alignment.center,
                child: ValueListenableBuilder(
                  valueListenable: widget.currentStory,
                  builder: (context, value, _) {
                    return value?.status == StatusEnum.notStarted
                        ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          onPressed: value != null ? () => start(value) : null,
                          child: Text('Start'),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                    elevation: 5,
                                  ),
                                  onPressed: value != null ? () {} : null,
                                  child: Text('Flip cards'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                    elevation: 5,
                                  ),
                                  onPressed: value != null ? () {} : null,
                                  child: Text('Clear votes'),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                elevation: 5,
                              ),
                              onPressed: value != null ? () {} : null,
                              child: Text('Skip story'),
                            ),
                          ],
                        );
                  },
                ),
              ),
            Container(
              height: 50,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
              ),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Players:', style: theme.textTheme.headlineSmall),
            ),
            if (currentUsersValue.isNotEmpty)
              ...currentUsersValue.mapIndexed(
                (index, u) => Container(
                  height: 50,
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                    borderRadius:
                        index == currentUsersValue.length - 1 && firebaseUser == null ? BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)) : null,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: VotingPlayer(
                    currentAppUser: widget.appUser,
                    appUser: u,
                    onObserverChanged: () => widget.onObserverChanged(u),
                    onUserRemoved: () => widget.onUserRemoved(u),
                    onUserRenamed: () => widget.onUserRenamed(u),
                  ),
                ),
              ),
            if (widget.appUser.moderator)
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!), right: BorderSide(color: Colors.grey[300]!)),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.all(0),
                    title: Text('Invite a teammate:', style: theme.textTheme.headlineSmall),
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(web.window.location.href, overflow: TextOverflow.ellipsis)),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: web.window.location.href));
                            },
                            icon: Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
