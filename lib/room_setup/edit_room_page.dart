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
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:web/web.dart' as web;

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

  late Room room;

  bool newStory = false;
  bool deleted = false;
  bool allCards = true;
  final cardsToUse = <bool>[];
  final stories = <Story>[];

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
        room = Room(dateAdded: DateTime.now(), id: Uuid().v4(), cardsToUse: [...VoteEnum.values], userId: _user.uid, status: RoomStatus.notStarted);
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
        room = Room.fromJson(json);
      });
    }

    deleted = room.dateDeleted != null;
    _nameController.text = room.name ?? '';
    allCards = widget.roomId == null || room.cardsToUse.length == VoteEnum.values.length;
    cardsToUse.addAll(VoteEnum.values.map((v) => allCards ? false : room.cardsToUse.contains(v)));

    final roomStories = await room_services.getStories(room.id);

    stories.addAll(roomStories);
    setState(() {});
  }

  void signOut() {
    AuthServices().signOut().then((_) {
      navigatorKey.currentContext!.go(Routes.login);
    });
  }

  void roomDeleteToggle(bool value) {
    setState(() {
      deleted = value;
    });
  }

  Future<void> saveRoom() async {
    if (_formKey.currentState!.validate()) {
      // save room
      room.name = _nameController.value.text;
      room.cardsToUse.clear();
      room.dateDeleted = deleted ? DateTime.now() : null;
      for (var index = 0; index < VoteEnum.values.length; index++) {
        if (cardsToUse[index] || allCards) {
          room.cardsToUse.add(VoteEnum.values[index]);
        }
      }
      final json = room.toJson();
      await FirebaseFirestore.instance.collection('rooms').doc(room.id).set(json);

      // save story
      for (var story in stories) {
        await FirebaseFirestore.instance.collection('rooms').doc(room.id).collection('stories').doc(story.id).set(story.toJson());
      }

      // save user room
      final userRoom = UserRoom.fromRoom(room);
      final userRoomsMap = userRoom.toJson();
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).collection('rooms').doc(room.id).set(userRoomsMap);

      navigatorKey.currentContext!.go(Routes.home);
    }
  }

  void useAllCardsToggle(bool? value) {
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

  void addStory(String roomId, List<Story> stories) {
    stories.add(Story(id: Uuid().v4(), description: '', status: StoryStatus.notStarted, added: true, order: stories.length, userId: _user.uid, roomId: roomId));
    setState(() {
      newStory = true;
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
          appBar: GiraffeAppBar(),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hyperlink(text: 'Back to list', onTap: () => web.window.history.back()),
                  Row(
                    spacing: 10,
                    children: [
                      Flexible(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            //hintStyle: theme.textTheme.bodyLarge!.copyWith(color: Colors.grey),
                            labelText: 'Room description',
                            //border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            //enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                            //focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: theme.primaryColor, width: 2.0)),
                            //filled: true,
                            //fillColor: theme.primaryColor,
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
                        children: [
                          Text('Deleted'),
                          Switch(
                            thumbIcon: thumbIcon,
                            value: deleted,
                            //activeColor: Colors.blue[600],
                            inactiveThumbColor: Colors.grey[500],
                            trackOutlineColor: borderColor,
                            onChanged: roomDeleteToggle,
                          ),
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
                              // fillColor: WidgetStateProperty.resolveWith((states) {
                              //   if (states.contains(WidgetState.selected)) {
                              //     return Colors.blueAccent;
                              //   }
                              //   return Colors.white;
                              // }),
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
                                  VoteEnum.values.mapIndexed((index, value) {
                                    final selected = index < cardsToUse.length ? cardsToUse[index] : false;
                                    return SizedBox(
                                      width: 120,
                                      child: CheckboxListTile(
                                        // fillColor: WidgetStateProperty.resolveWith((states) {
                                        //   if (states.contains(WidgetState.selected)) {
                                        //     return Colors.blueAccent;
                                        //   }
                                        //   return Colors.white;
                                        // }),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.all(0),
                                        splashRadius: 10,
                                        tristate: false,
                                        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
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
                        onPressed: () => addStory(room.id, stories),
                        child: Text('Add Story'),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    child: Column(
                      spacing: 10,
                      children:
                          stories
                              .mapIndexed(
                                (index, story) => EditRoomStory(
                                  story: story,
                                  onDelete: () => removeStory(stories, story),
                                  onMoveUp: index == 0 ? null : () => moveStoryUp(stories, index, story),
                                  onMoveDown: index >= stories.length - 1 ? null : () => moveStoryDown(stories, index, story),
                                  nextOrder: stories.length,
                                  userId: _user.uid,
                                  roomId: room.id,
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
