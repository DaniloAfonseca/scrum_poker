import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/room_setup/room_story.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/user_room.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class UserRoomPage extends StatefulWidget {
  final String? roomId;
  const UserRoomPage({super.key, this.roomId});

  @override
  State<UserRoomPage> createState() => _UserRoomPageState();
}

class _UserRoomPageState extends State<UserRoomPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final rooms = <Room>[];
  Room? room;
  bool newStory = false;
  bool deleted = false;
  bool allCards = true;
  final cardsToUse = <bool>[];

  static const WidgetStateProperty<Icon> thumbIcon = WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
    WidgetState.selected: Icon(Icons.check),
    WidgetState.any: Icon(Icons.close),
  });

  static const WidgetStateProperty<Color> borderColor = WidgetStateProperty<Color>.fromMap(<WidgetStatesConstraint, Color>{
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
        room = Room(stories: [], dateAdded: DateTime.now(), id: Uuid().v4(), cardsToUse: [...VoteEnum.values], userId: user.uid, status: StatusEnum.notStarted);
      });
    } else {
      final dbUserRooms = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('rooms').doc(widget.roomId).snapshots().first;
      if (dbUserRooms.data() == null) {
        // room not found
        return;
      }

      final dbRoom = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots().first;
      final json = dbRoom.data()!;
      setState(() {
        room = Room.fromJson(json);
      });
    }

    deleted = room!.dateDeleted != null;
    _nameController.text = room!.name ?? '';
    allCards = widget.roomId == null || room!.cardsToUse.length == VoteEnum.values.length;
    cardsToUse.addAll(VoteEnum.values.map((v) => allCards ? false : room!.cardsToUse.contains(v)));
  }

  void signOut() {
    AuthServices().signOut().then((_) {
      navigatorKey.currentContext!.go(Routes.login);
    });
  }

  void roomDeleteToggle(bool value) {
    setState(() {
      deleted = value;
      room!.dateDeleted = deleted ? DateTime.now() : null;
    });
  }

  Future<void> saveRoom() async {
    if (_formKey.currentState!.validate()) {
      room!.name = _nameController.value.text;
      room!.cardsToUse.clear();
      for (var index = 0; index < VoteEnum.values.length; index++) {
        if (cardsToUse[index] || allCards) {
          room!.cardsToUse.add(VoteEnum.values[index]);
        }
      }
      final json = room!.toJson();
      await FirebaseFirestore.instance.collection('rooms').doc(room!.id).set(json);

      final userRoom = UserRoom.fromRoom(room!);

      final userRoomsMap = userRoom.toJson();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('rooms').doc(room!.id).set(userRoomsMap);

      navigatorKey.currentContext!.go(Routes.home);
    }
  }

  void useAllCardsToggle(value) {
    setState(() {
      allCards = value == true;
      for (var index = 0; index < VoteEnum.values.length; index++) {
        cardsToUse[index] = false;
      }
    });
  }

  void cardInUse(int index, bool? value) {
    setState(() {
      allCards = false;
      cardsToUse[index] = value == true;
    });
  }

  void addStory() {
    room!.stories.add(Story(id: Uuid().v4(), description: '', status: StatusEnum.notStarted, votes: [], added: true));
    setState(() {
      newStory = true;
    });
  }

  void removeStory(Story story) {
    room!.stories.remove(story);
    setState(() {});
  }

  void moveStoryUp(int index, Story story) {
    final previousStory = room!.stories[index - 1];
    room!.stories[index - 1] = story;
    room!.stories[index] = previousStory;
    setState(() {});
  }

  void moveStoryDown(int index, Story story) {
    final nextStory = room!.stories[index + 1];
    room!.stories[index + 1] = story;
    room!.stories[index] = nextStory;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraint) {
        return Scaffold(
          appBar: AppBar(
            actionsPadding: const EdgeInsets.only(right: 16.0),
            title: Text('Scrum Poker', style: theme.textTheme.displayMedium),
            actions: [CircleAvatar(backgroundColor: Colors.blueAccent, child: IconButton(icon: Icon(Icons.person_outline, color: Colors.white), onPressed: signOut))],
          ),
          body:
              room == null
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        spacing: 10,
                        children: [
                          Row(
                            spacing: 10,
                            children: [
                              Flexible(
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintStyle: theme.textTheme.bodyLarge!.copyWith(color: Colors.grey),
                                    labelText: 'Room description',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
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
                                spacing: 5,
                                children: [
                                  Text('Deleted'),
                                  Switch(
                                    thumbIcon: thumbIcon,
                                    value: deleted,
                                    activeColor: Colors.blue[600],
                                    inactiveThumbColor: Colors.grey[500],
                                    trackOutlineColor: borderColor,
                                    onChanged: roomDeleteToggle,
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
                                onPressed: saveRoom,
                                child: Text('Save'),
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
                                      fillColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.blueAccent;
                                        }
                                        return Colors.white;
                                      }),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      value: allCards,
                                      title: Text('Use all cards'),
                                      contentPadding: EdgeInsets.all(0),
                                      splashRadius: 10,
                                      tristate: false,
                                      checkboxSemanticLabel: 'Use all cards',
                                      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                      onChanged: useAllCardsToggle,
                                    ),
                                  ),
                                  SizedBox(
                                    width: constraint.maxWidth - 40,
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.start,
                                      children:
                                          VoteEnum.values
                                              .mapIndexed(
                                                (index, value) => SizedBox(
                                                  width: 120,
                                                  child: CheckboxListTile(
                                                    fillColor: WidgetStateProperty.resolveWith((states) {
                                                      if (states.contains(WidgetState.selected)) {
                                                        return Colors.blueAccent;
                                                      }
                                                      return Colors.white;
                                                    }),
                                                    controlAffinity: ListTileControlAffinity.leading,
                                                    contentPadding: EdgeInsets.all(0),
                                                    splashRadius: 10,
                                                    tristate: false,
                                                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                                    value: cardsToUse[index],
                                                    onChanged: (v) => cardInUse(index, v),
                                                    title: Text(value.label),
                                                  ),
                                                ),
                                              )
                                              .toList(),
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
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  elevation: 5,
                                ),
                                onPressed: addStory,
                                child: Text('Add Story'),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            child: Column(
                              spacing: 10,
                              children:
                                  room!.stories
                                      .mapIndexed(
                                        (index, story) => RoomStory(
                                          key: ValueKey(story),
                                          story: story,
                                          onDelete: () => removeStory(story),
                                          onMoveUp: index == 0 ? null : () => moveStoryUp(index, story),
                                          onMoveDown: index >= room!.stories.length - 1 ? null : () => moveStoryDown(index, story),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }
}
