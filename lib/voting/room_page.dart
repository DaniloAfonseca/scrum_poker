import 'dart:async';
import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/shared/widgets/app_bar.dart';
import 'package:scrum_poker/shared/widgets/bottom_bar.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:scrum_poker/voting/room_login.dart';
import 'package:scrum_poker/voting/players/voting_players.dart';
import 'package:scrum_poker/voting/list/voting_list.dart';
import 'package:scrum_poker/voting/story/voting_story.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop' as js;

class RoomPage extends StatefulWidget {
  final String roomId;
  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  var _user = FirebaseAuth.instance.currentUser;

  final _appUser = ValueNotifier<AppUser?>(null);
  final _oldCurrentUsers = <AppUser>[];
  final _oldStories = <Story>[];
  final _currentStoryVN = ValueNotifier<Story?>(null);
  final _settingsManager = SettingsManager();

  bool _isLoading = true;
  Room? _oldRoom;
  bool _listenToRoomChanges = false;
  bool _listenToStoryChanges = false;
  bool _listenToUserChanges = false;

  bool _autoFlip = false;

  @override
  void initState() {
    FirebaseFirestore.instance.collection('rooms').snapshots(includeMetadataChanges: true).listen(onRoomsData);
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('stories').snapshots(includeMetadataChanges: true).listen(onStoriesData);
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('currentUsers').snapshots(includeMetadataChanges: true).listen(onCurrentUsersData);

    _autoFlip = _settingsManager.autoFlip;

    web.window.onbeforeunload = (JSAny data) {
      if (_appUser.value != null) {
        room_services.removeUser(_appUser.value!);
      }
    }.toJS;

    web.window.onpopstate = (JSAny data) {
      if (_appUser.value != null) {
        room_services.removeUser(_appUser.value!);
      }
    }.toJS;

    _settingsManager.addListener(onSettingChanged);

    loadUser();
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    _settingsManager.removeListener(onSettingChanged);

    super.dispose();
  }

  /// listens for setting change
  void onSettingChanged() {
    setState(() {
      if (_autoFlip != _settingsManager.autoFlip) {
        _autoFlip = _settingsManager.autoFlip;
        snackbarMessenger(message: 'Auto flip rooms is ${_autoFlip ? 'ON' : 'OFF'}');
      }
    });
  }

  /// listens for room changes
  void onRoomsData(QuerySnapshot<Map<String, dynamic>> event) {
    // changes were found
    if (event.docChanges.isNotEmpty && _listenToRoomChanges) {
      // list of changed rooms
      final rooms = event.docChanges.where((t) => t.doc.data() != null).map((t) => Room.fromJson(t.doc.data()!)).where((r) => r.id == widget.roomId).toList();
      if (rooms.isNotEmpty) {
        final messages = <String>[];
        if (_oldRoom != null) {
          final room = rooms.first;
          if (room.name != _oldRoom!.name) {
            messages.add('Room name changed to ${room.name}.');
          }
          if (room.status != _oldRoom!.status) {
            messages.add('Room status changed to ${room.status.name}.');
          }
          if (_oldRoom!.dateDeleted == null && room.dateDeleted != null) {
            messages.add('Room ${room.name} has been deleted.');
          }
        }
        _oldRoom = rooms.first;
        showSnackBar(messages);
      } else {
        _oldRoom = null;
      }
    }
    _listenToRoomChanges = true;
  }

  /// listens for story changes
  Future<void> onStoriesData(QuerySnapshot<Map<String, dynamic>> event) async {
    // get all stories
    final stories = event.docs.map((t) => Story.fromJson(t.data())).toList();

    // story changes were found
    if (event.docChanges.isNotEmpty && _listenToStoryChanges) {
      final messages = <String>[];

      for (final change in event.docChanges) {
        if (change.doc.exists) {
          final story = Story.fromJson(change.doc.data()!);
          switch (change.type) {
            case DocumentChangeType.added:
              messages.add('${story.description} has been added to the room.');
              break;
            case DocumentChangeType.removed:
              messages.add('${story.description} has been remove from the room.');
              break;
            case DocumentChangeType.modified:
              final oldStory = _oldStories.firstWhereOrNull((t) => t.id == story.id);
              // check status
              if (oldStory?.status != story.status) {
                if (story.status == StoryStatus.notStarted) {
                  messages.add('Story "${story.description}" was moved to active.');
                }
                if (story.status == StoryStatus.skipped) {
                  messages.add('Story "${story.description}" was skipped.');
                }
                if (story.status == StoryStatus.voted) {
                  messages.add('Story "${story.description}" cards were flipped.');
                }
                if (story.status == StoryStatus.ended) {
                  messages.add('Story "${story.description}" has ended.');
                }
              }

              if (oldStory?.currentStory != story.currentStory && story.currentStory) {
                messages.add('Current story as changed. "${story.description}" is now the current story.');
              }
          }
        }
      }

      _oldStories.clear();
      _oldStories.addAll(stories);
      showSnackBar(messages);
    }
    _listenToStoryChanges = true;

    // auto closes the room
    if (stories.where((t) => [StoryStatus.ended, StoryStatus.skipped].contains(t.status)).length == stories.length) {
      await room_services.closeRoom(stories.first.roomId);
    }
  }

  /// listens to users changes
  void onCurrentUsersData(QuerySnapshot<Map<String, dynamic>> event) {
    // user changes were found
    if (event.docChanges.isNotEmpty && _listenToUserChanges) {
      final messages = <String>[];
      final users = event.docs.map((t) => AppUser.fromJson(t.data())).toList();
      for (final change in event.docChanges) {
        if (change.doc.exists) {
          final user = AppUser.fromJson(change.doc.data()!);
          switch (change.type) {
            case DocumentChangeType.added:
              if (user.id != _appUser.value?.id) {
                messages.add('${user.name} joined the room.');
              }
              break;
            case DocumentChangeType.removed:
              if (user.id != _appUser.value?.id) {
                messages.add('${user.name} left the room.');
              }
              break;
            case DocumentChangeType.modified:
              final oldUser = _oldCurrentUsers.firstWhereOrNull((t) => t.id == user.id);
              if (oldUser?.observer != user.observer) {
                if (user.observer) {
                  messages.add('${user.name} is now an observer.');
                } else {
                  messages.add('${user.name} is now a player.');
                }
              }
          }
        }
      }
      _oldCurrentUsers.clear();
      _oldCurrentUsers.addAll(users);
      showSnackBar(messages);
    }
    _listenToUserChanges = true;
  }

  /// listens to current story changes
  void handleCurrentStoryChanges(final List<AppUser> users, final List<Vote> votes) {
    if (_currentStoryVN.value == null) {
      return;
    }
    final currentStory = _currentStoryVN.value!;
    if (currentStory.status == StoryStatus.started && _autoFlip && users.length == votes.length) {
      room_services.flipCards(currentStory, votes);
    }
  }

  /// check if current stored user is a moderator for the room
  /// if not this user will not be a moderator
  Future<void> checkUser() async {
    if (_user != null) {
      // get user rooms
      final rooms = await room_services.getUserRooms(_user!.uid);
      final roomId = widget.roomId;

      // logout the user if invited to a different room
      if (!rooms.any((r) => r.id == roomId)) {
        _user = null;
        _appUser.value = null;
      }
    }
  }

  /// load user
  Future<void> loadUser() async {
    setState(() {
      _isLoading = true;
    });

    if (_user?.metadata != null) {
      final appUser = AppUser.fromUser(_user!, widget.roomId);
      _settingsManager.updateAppUser(appUser);
    }

    _appUser.value = _settingsManager.appUser;

    setState(() {
      _isLoading = false;
    });
  }

  /// log in into the room
  Future<void> logIn(String username) async {
    if (_user != null && _user!.displayName != username) {
      await _user!.updateDisplayName(username);
    }

    final appUser = _user == null ? AppUser(name: username, id: const Uuid().v4()) : AppUser.fromUser(_user!, widget.roomId);

    _settingsManager.updateAppUser(appUser);

    _appUser.value = appUser;
  }

  /// show snackbar messages
  ///
  /// [messages] list of messages
  void showSnackBar(List<String> messages) {
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;

    // show messages
    for (final message in messages) {
      final duration = Duration(milliseconds: controller == null ? 0 : 1000);
      Future.delayed(duration, () {
        controller = snackbarMessenger(message: message);
      });
    }
  }

  List<String> getVoteChanges(List<Vote> oldVotes, List<Vote> newVotes) {
    final messages = <String>[];
    for (final newVote in newVotes) {
      final oldVote = oldVotes.firstWhereOrNull((t) => t.userId == newVote.userId);
      if (oldVote == null) {
        messages.add('${newVote.userName} just voted.');
      } else if (oldVote.value != newVote.value) {
        messages.add('${newVote.userName} changed his/her vote.');
      }
    }

    return messages;
  }

  Future<void> renameUser(AppUser appUser) async {
    _appUser.value = null;
    await room_services.removeUser(appUser);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return ValueListenableBuilder(
      valueListenable: _appUser,
      builder: (ctx, value, child) {
        return Scaffold(
          key: Key('${_appUser.value}'),
          appBar: (_appUser.value == null)
              ? null
              : GiraffeAppBar(
                  onSignOut: () {
                    room_services.removeUser(_appUser.value!);
                    setState(() {
                      _appUser.value = null;
                    });
                  },
                ),

          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_appUser.value == null)
              ? RoomLogin(isModerator: _user != null, login: logIn)
              : StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final map = snapshot.data!.data()!;
                    final room = Room.fromJson(map);

                    _appUser.value!.roomId = room.id;

                    room_services.addUserToRoom(_appUser.value);

                    return StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('stories').snapshots(),
                      builder: (context, snapshot) {
                        final maps = snapshot.data?.docs.map((t) => t.data());
                        final stories = maps?.map((t) => Story.fromJson(t)).toList() ?? <Story>[];
                        stories.sortBy((t) => t.order);

                        if (_user != null) {
                          room_services.setCurrentStory(stories);
                        }

                        _currentStoryVN.value = stories.firstWhereOrNull((t) => t.currentStory);

                        return Container(
                          // decoration: const BoxDecoration(
                          //   image: DecorationImage(
                          //     image: SvgPicture.asset('images/logo_dark_mode.svg'),
                          //     alignment: Alignment.bottomLeft,
                          //     colorFilter: ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]),
                          //     opacity: 0.2,
                          //     fit: BoxFit.contain,
                          //     filterQuality: FilterQuality.high,
                          //   ),
                          // ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: mediaQuery.size.width > 900
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(room.name!, style: theme.textTheme.headlineLarge),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          spacing: 20,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                spacing: 20,
                                                children: [
                                                  VotingStory(appUser: _appUser.value, roomId: room.id),
                                                  VotingList(room: room),
                                                ],
                                              ),
                                            ),

                                            Flexible(
                                              flex: 1,
                                              child: VotingPlayers(
                                                onVotingChange: handleCurrentStoryChanges,
                                                currentStoryVN: _currentStoryVN,
                                                room: room,
                                                appUser: _appUser.value!,
                                                onUserRenamed: renameUser,
                                                openStoryCount: stories.where((t) => [StoryStatus.notStarted, StoryStatus.started, StoryStatus.voted].contains(t.status)).length,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : ValueListenableBuilder(
                                      valueListenable: _currentStoryVN,
                                      builder: (context, currentStory, child) {
                                        return Column(
                                          spacing: 10,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(room.name!, style: theme.textTheme.headlineLarge),
                                            if (currentStory?.url == null) Text(currentStory?.fullDescription ?? '', style: theme.textTheme.headlineSmall),
                                            if (currentStory?.url != null)
                                              Hyperlink(text: currentStory?.fullDescription ?? '', textStyle: theme.textTheme.headlineSmall!, url: currentStory!.url!),
                                            VotingPlayers(
                                              currentStoryVN: _currentStoryVN,
                                              room: room,
                                              appUser: _appUser.value!,
                                              onUserRenamed: (appUser) => renameUser(appUser),
                                              openStoryCount: stories.where((t) => [StoryStatus.notStarted, StoryStatus.started, StoryStatus.voted].contains(t.status)).length,
                                            ),
                                            VotingStory(showStoryDescription: false, appUser: _appUser.value, roomId: room.id),
                                            VotingList(room: room),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          bottomSheet: bottomBar(),
        );
      },
    );
  }
}
