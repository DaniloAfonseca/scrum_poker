import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/dashboard/room_story_editor.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:uuid/uuid.dart';
import 'package:scrum_poker/shared/models/user.dart' as u;

class UserRoomEditor extends StatefulWidget {
  final u.User user;
  final String? roomId;
  const UserRoomEditor({super.key, required this.user, this.roomId});

  @override
  State<UserRoomEditor> createState() => _UserRoomEditorState();
}

class _UserRoomEditorState extends State<UserRoomEditor> {
  final firebaseUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late u.User user;
  late Room room;
  bool newStory = false;

  @override
  void initState() {
    user = widget.user;
    room = widget.roomId == null ? Room(stories: [], dateAdded: DateTime.now(), id: Uuid().v4()) : user.rooms.firstWhere((t) => t.id == widget.roomId);
    _nameController.value = TextEditingValue(text: room.name ?? '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                        labelText: 'Room description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
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
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        room.name = _nameController.value.text;
                        if (widget.roomId == null) {
                          user.rooms.add(room);
                        }
                        final json = user.toJson();
                        await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set(json);
                        navigatorKey.currentContext!.go(Routes.dashboard);
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      room.stories.add(Story(description: '', status: StoryStatusEnum.newStory, votes: [], added: true));
                      setState(() {
                        newStory = true;
                      });
                    },
                    child: Text('Add Story'),
                  ),
                ],
              ),
              SingleChildScrollView(child: Column(spacing: 10, children: room.stories.map((story) => RoomStoryEditor(story: story)).toList())),
            ],
          ),
        ),
      ),
    );
  }
}
