import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/room_setup/edit_room_story.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/user_room.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/shared/widgets/app_bar.dart';
import 'package:scrum_poker/shared/widgets/bottom_bar.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class EditRoomPage extends StatefulWidget {
  final String? roomId;
  const EditRoomPage({super.key, this.roomId});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late Room _room;

  bool _deleted = false;
  bool _allCards = true;
  final _cardsToUse = <bool>[];
  final _stories = <Story>[];

  static const WidgetStateProperty<Icon> _thumbIcon = WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
    WidgetState.selected: Icon(Icons.check),
    WidgetState.any: Icon(Icons.close),
  });

  static const WidgetStateProperty<Color> _borderColor = WidgetStateProperty<Color>.fromMap(<WidgetStatesConstraint, Color>{
    WidgetState.selected: Colors.transparent,
    WidgetState.any: Colors.transparent,
  });

  @override
  void initState() {
    loadRoom();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> loadRoom() async {
    if (widget.roomId == null) {
      setState(() {
        _room = Room(dateAdded: DateTime.now(), id: const Uuid().v4(), cardsToUse: [...VoteEnum.values], userId: _user.uid, status: RoomStatus.notStarted);
      });
    } else {
      final dbUserRooms = await FirebaseFirestore.instance.collection('users').doc(_user.uid).collection('rooms').doc(widget.roomId).snapshots().first;
      if (dbUserRooms.data() == null) {
        // room not found
        return;
      }

      final dbRoom = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots().first;
      final json = dbRoom.data()!;
      setState(() {
        _room = Room.fromJson(json);
      });
    }

    _deleted = _room.dateDeleted != null;
    _nameController.text = _room.name ?? '';
    _allCards = widget.roomId == null || _room.cardsToUse.length == VoteEnum.values.length;
    _cardsToUse.addAll(VoteEnum.values.map((v) => _allCards ? false : _room.cardsToUse.contains(v)));

    final roomStories = await room_services.getStories(_room.id);

    _stories.addAll(roomStories);
    setState(() {});
  }

  void signOut() {
    AuthServices().signOut().then((_) {
      navigatorKey.currentContext!.go(Routes.login);
    });
  }

  void roomDeleteToggle(bool value) {
    setState(() {
      _deleted = value;
    });
  }

  Future<void> saveRoom() async {
    if (_formKey.currentState!.validate()) {
      // save room
      _room.name = _nameController.value.text;
      _room.cardsToUse.clear();
      _room.dateDeleted = _deleted ? DateTime.now() : null;
      _room.isDeleted = _deleted;
      for (var index = 0; index < VoteEnum.values.length; index++) {
        if (_cardsToUse[index] || _allCards) {
          _room.cardsToUse.add(VoteEnum.values[index]);
        }
      }
      final json = _room.toJson();
      await FirebaseFirestore.instance.collection('rooms').doc(_room.id).set(json);

      // save story
      for (var story in _stories.where((s) => s.added == false)) {
        await FirebaseFirestore.instance.collection('rooms').doc(_room.id).collection('stories').doc(story.id).set(story.toJson());
      }

      // remove deleted stories
      final existingStories = await room_services.getStories(_room.id);
      for (var existingStory in existingStories) {
        if (_stories.any((t) => t.id == existingStory.id)) continue;
        await FirebaseFirestore.instance.collection('rooms').doc(_room.id).collection('stories').doc(existingStory.id).delete();
      }

      // save user room
      final userRoom = UserRoom.fromRoom(_room);
      userRoom.activeStories = _stories.where((t) => t.status.active).length;
      userRoom.skippedStories = _stories.where((t) => t.status == StoryStatus.skipped).length;
      userRoom.completedStories = _stories.where((t) => !t.status.active).length;
      userRoom.allStories = _stories.length;
      userRoom.isDeleted = _room.isDeleted;
      final userRoomsMap = userRoom.toJson();
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).collection('rooms').doc(_room.id).set(userRoomsMap);

      if (_stories.any((s) => s.added)) {
        snackbarMessenger(message: 'Unsaved story were skipped.');
        await Future.delayed(const Duration(microseconds: 500));
      }

      navigatorKey.currentContext!.go(Routes.home);
    }
  }

  void useAllCardsToggle(bool? value) {
    setState(() {
      _allCards = value == true;
      for (var index = 0; index < VoteEnum.values.length; index++) {
        _cardsToUse[index] = false;
      }
    });
  }

  void cardInUse(int index, bool? value) {
    setState(() {
      _allCards = false;
      _cardsToUse[index] = value == true;
    });
  }

  void addStory(String roomId, List<Story> stories) {
    setState(() {
      stories.add(Story(id: const Uuid().v4(), description: '', status: StoryStatus.notStarted, added: true, order: stories.length, userId: _user.uid, roomId: roomId));
    });
  }

  void removeStory(List<Story> stories, Story story) {
    setState(() {
      stories.remove(story);
    });
  }

  void moveStoryUp(List<Story> stories, int index, Story story) {
    setState(() {
      final previousStory = stories[index - 1];
      stories[index - 1] = story;
      stories[index] = previousStory;
      setStoriesOrder(stories);
    });
  }

  void moveStoryDown(List<Story> stories, int index, Story story) {
    setState(() {
      final nextStory = stories[index + 1];
      stories[index + 1] = story;
      stories[index] = nextStory;
      setStoriesOrder(stories);
    });
  }

  void setStoriesOrder(List<Story> stories) {
    for (var i = 0; i < stories.length; i++) {
      stories[i].order = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraint) {
        return Scaffold(
          appBar: const GiraffeAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: 20,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hyperlink(text: 'Back to list', onTap: () => context.go(Routes.home)),
                    Row(
                      spacing: 10,
                      children: [
                        Flexible(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Room description'),
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Invalid room description';
                              }
                              return null;
                            },
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Deleted'),
                            Switch(thumbIcon: _thumbIcon, value: _deleted, inactiveThumbColor: Colors.grey[500], trackOutlineColor: _borderColor, onChanged: roomDeleteToggle),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          onPressed: () => saveRoom(),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                value: _allCards,
                                title: const Text('Use all cards'),
                                contentPadding: const EdgeInsets.all(0),
                                splashRadius: 10,
                                tristate: false,
                                checkboxSemanticLabel: 'Use all cards',
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                onChanged: useAllCardsToggle,
                              ),
                            ),
                            SizedBox(
                              width: constraint.maxWidth - 40,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: VoteEnum.values.mapIndexed((index, value) {
                                  final selected = index < _cardsToUse.length ? _cardsToUse[index] : false;
                                  return SizedBox(
                                    width: 120,
                                    child: CheckboxListTile(
                                      controlAffinity: ListTileControlAffinity.leading,
                                      contentPadding: const EdgeInsets.all(0),
                                      splashRadius: 10,
                                      tristate: false,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      value: selected,
                                      onChanged: (v) => cardInUse(index, v),
                                      title: Text(value.label),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          onPressed: () => addStory(_room.id, _stories),
                          child: const Text('Add Story'),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      child: Column(
                        spacing: 10,
                        children: _stories
                            .mapIndexed(
                              (index, story) => EditRoomStory(
                                story: story,
                                onDelete: () => removeStory(_stories, story),
                                onMoveUp: index == 0 ? null : () => moveStoryUp(_stories, index, story),
                                onMoveDown: index >= _stories.length - 1 ? null : () => moveStoryDown(_stories, index, story),
                                nextOrder: _stories.length,
                                userId: _user.uid,
                                roomId: _room.id,
                                onCancelled: () {
                                  if (story.added) {
                                    setState(() {
                                      _stories.remove(story);
                                    });
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomSheet: bottomBar(),
        );
      },
    );
  }
}
