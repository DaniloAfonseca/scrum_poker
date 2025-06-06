import 'package:flutter/material.dart';
import 'package:scrum_poker/dashboard/room_story_editor.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/story.dart';

class UserRoomEditor extends StatefulWidget {
  final String? roomId;
  const UserRoomEditor({super.key, this.roomId});

  @override
  State<UserRoomEditor> createState() => _UserRoomEditorState();
}

class _UserRoomEditorState extends State<UserRoomEditor> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Room room;
  bool newStory = false;

  @override
  void initState() {
    if (widget.roomId != null) {
      room = Room(name: 'Room 1', dateAdded: DateTime.now(), id: '', stories: [Story(description: 'Make banner', status: StoryStatusEnum.newStory, votes: [])]);
      _nameController.value = TextEditingValue(text: room.name);
    }
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
              TextFormField(
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
