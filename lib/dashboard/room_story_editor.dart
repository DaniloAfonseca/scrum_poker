import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomStoryEditor extends StatefulWidget {
  final Story? story;
  const RoomStoryEditor({super.key, this.story});

  @override
  State<RoomStoryEditor> createState() => _RoomStoryEditorState();
}

class _RoomStoryEditorState extends State<RoomStoryEditor> {
  final _menuKey = GlobalKey();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  late Story story;
  bool isEditing = false;

  @override
  void initState() {
    story = widget.story ?? Story(description: '', status: StoryStatusEnum.newStory, votes: [], added: true);
    isEditing = (widget.story?.added ?? false) || widget.story == null;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isEditing ? Colors.white : const Color.fromARGB(255, 255, 229, 196),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEditing) ...[
                  Text(story.description, style: theme.textTheme.headlineLarge),
                  if (story.url != null)
                    GestureDetector(
                      onTap: () async {
                        final Uri uri = Uri.parse(widget.story!.url!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not launch ${widget.story!.url!}';
                        }
                      },
                      child: Text(widget.story!.url!, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    ),
                ],
                if (isEditing) ...[
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Story description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Invalid story description';
                      }

                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Story URL',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Invalid story description';
                      }

                      if (!Uri.parse(value).isAbsolute) {
                        return 'Invalid URL';
                      }

                      return null;
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        child: Text('Save'),
                        onPressed: () {
                          story.description = _descriptionController.value.text;
                          story.url = _urlController.value.text;
                          setState(() {
                            isEditing = false;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (!isEditing)
            IconButton(
              key: _menuKey,
              onPressed: () {
                RenderBox box = _menuKey.currentContext!.findRenderObject() as RenderBox;
                Offset position = box.localToGlobal(Offset.zero);
                showMenu(
                  context: context,
                  items: [
                    PopupMenuItem(
                      child: Row(spacing: 10, children: [Icon(Icons.edit), Text('Edit')]),
                      onTap: () {
                        _descriptionController.value = TextEditingValue(text: story.description);
                        _urlController.value = TextEditingValue(text: story.url ?? '');
                        setState(() {
                          isEditing = true;
                        });
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
