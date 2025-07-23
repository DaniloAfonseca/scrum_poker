import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrum_poker/room_setup/edit_room_story_jira_search.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/managers/jira_credentials_manager.dart';
import 'package:scrum_poker/shared/models/jira_issue_response.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:uuid/uuid.dart';

class EditRoomStory extends StatefulWidget {
  final Story? story;
  final FutureOr<void> Function() onDelete;
  final FutureOr<void> Function()? onMoveUp;
  final FutureOr<void> Function()? onMoveDown;
  final int nextOrder;
  final String roomId;
  final String userId;
  const EditRoomStory({super.key, this.story, required this.onDelete, this.onMoveUp, this.onMoveDown, required this.nextOrder, required this.userId, required this.roomId});

  @override
  State<EditRoomStory> createState() => _EditRoomStoryState();
}

class _EditRoomStoryState extends State<EditRoomStory> {
  final _menuKey = GlobalKey();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late Story _story;
  bool _isEditing = false;
  bool _integratedWithJira = false;
  StoryType? _storyType;
  String? _jiraKey;

  String? _jiraUrl;

  @override
  void initState() {
    _story =
        widget.story ??
        Story(id: const Uuid().v4(), description: '', status: StoryStatus.notStarted, added: true, order: widget.nextOrder, userId: widget.userId, roomId: widget.roomId);
    _isEditing = (widget.story?.added ?? false) || widget.story == null;

    _descriptionController.text = _story.description;
    _urlController.text = _story.url ?? '';
    _storyType = _story.storyType;
    _jiraKey = _story.jiraKey;

    _integratedWithJira = JiraCredentialsManager().currentCredentials != null;

    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _urlController.dispose();

    super.dispose();
  }

  void edit() async {
    _descriptionController.text = _story.description;
    _urlController.text = _story.url ?? '';
    setState(() {
      _isEditing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _isEditing ? theme.cardColor : theme.primaryColor,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                spacing: 5,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        if (_story.storyType?.icon != null) Icon(_story.storyType!.icon, color: _story.storyType!.color),
                        Flexible(
                          child: Text(_story.fullDescription, style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white), softWrap: true),
                        ),
                        if (_story.estimate != null || _story.revisedEstimate != null) const SizedBox(width: 5),
                        if (_story.estimate != null)
                          Tooltip(
                            message: 'Estimated story point',
                            child: Container(
                              color: theme.dividerColor,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              child: Text(_story.estimate.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: theme.primaryColor)),
                            ),
                          ),
                        if (_story.revisedEstimate != null)
                          Tooltip(
                            message: 'Story points',
                            child: Container(
                              color: Colors.blueAccent,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              child: Text(_story.revisedEstimate.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
                            ),
                          ),
                      ],
                    ),

                    if (_story.url != null) Hyperlink(text: widget.story!.url!, color: Colors.white, url: widget.story!.url!),
                  ],
                  if (_isEditing) ...[
                    _integratedWithJira
                        ? EditRoomStoryJiraSearch(
                            currentValue: _descriptionController.text,
                            onSelectedChanged: ({bool? hasAnyType, JiraIssue? juraIssue}) {
                              if (juraIssue == null) {
                                _descriptionController.text = '';
                                _urlController.text = '';
                                setState(() {
                                  _storyType = null;
                                  _jiraKey = null;
                                });
                              } else {
                                _descriptionController.text = '${juraIssue.fields!.summary}';
                                if (_jiraUrl?.endsWith('/') == true) {
                                  _jiraUrl = _jiraUrl!.substring(0, _jiraUrl!.length - 1);
                                }
                                if (_jiraUrl != null && _jiraUrl!.isNotEmpty) {
                                  _urlController.text = '$_jiraUrl/${juraIssue.key}';
                                }

                                setState(() {
                                  _storyType = !(hasAnyType ?? false)
                                      ? null
                                      : juraIssue.fields!.issueType?.name == 'Bug'
                                      ? StoryType.bug
                                      : juraIssue.fields!.issueType?.name == 'Story'
                                      ? StoryType.workItem
                                      : StoryType.others;
                                  _jiraKey = juraIssue.key;
                                });
                              }
                            },
                          )
                        : TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Story title'),
                            keyboardType: TextInputType.text,
                            validator: _integratedWithJira
                                ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Invalid story description';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: 'Story URL'),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value != null && !Uri.parse(value).isAbsolute) {
                          return 'Invalid URL';
                        }
                        return null;
                      },
                    ),
                    if (_integratedWithJira)
                      DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<StoryType>(
                          decoration: const InputDecoration(labelText: 'Story type'),
                          value: _storyType,
                          items: StoryType.values
                              .map(
                                (t) => DropdownMenuItem<StoryType>(
                                  value: t,
                                  child: Row(
                                    children: [
                                      if (t.icon != null) Icon(t.icon, color: t.color),
                                      Text(t.description),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _storyType = v;
                            });
                          },
                        ),
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
                          child: const Text('Update'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _story.description = _descriptionController.value.text;
                              _story.url = _urlController.value.text;
                              _story.added = false;
                              _story.storyType = _storyType;
                              _story.jiraKey = _jiraKey;
                              setState(() {
                                _isEditing = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          child: const Text('Cancel'),
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!_isEditing)
              IconButton(
                key: _menuKey,
                onPressed: () {
                  RenderBox box = _menuKey.currentContext!.findRenderObject() as RenderBox;
                  Offset position = box.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    items: [
                      PopupMenuItem(
                        onTap: edit,
                        child: const Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blueAccent),
                            SizedBox(width: 5),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: widget.onDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 5),
                            Text('Delete'),
                          ],
                        ),
                      ),
                      if (widget.onMoveUp != null)
                        PopupMenuItem(
                          onTap: widget.onMoveUp,
                          child: const Row(
                            children: [
                              Icon(Icons.move_up_outlined, color: Colors.blueAccent),
                              SizedBox(width: 5),
                              Text('Move up'),
                            ],
                          ),
                        ),
                      if (widget.onMoveDown != null)
                        PopupMenuItem(
                          onTap: widget.onMoveDown,
                          child: const Row(
                            children: [
                              Icon(Icons.move_down_outlined, color: Colors.blueAccent),
                              SizedBox(width: 5),
                              Text('Move down'),
                            ],
                          ),
                        ),
                    ],
                    position: RelativeRect.fromLTRB(position.dx - 60, position.dy + 40, position.dx, position.dy),
                  );
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
