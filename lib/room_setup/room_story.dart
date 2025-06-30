import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/jira_work_item.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:uuid/uuid.dart';

class RoomStory extends StatefulWidget {
  final Story? story;
  final FutureOr<void> Function() onDelete;
  final FutureOr<void> Function()? onMoveUp;
  final FutureOr<void> Function()? onMoveDown;
  final int nextOrder;
  const RoomStory({super.key, this.story, required this.onDelete, this.onMoveUp, this.onMoveDown, required this.nextOrder});

  @override
  State<RoomStory> createState() => _RoomStoryState();
}

class _RoomStoryState extends State<RoomStory> {
  final _menuKey = GlobalKey();
  final _searchController = SearchController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  late AppUser user;
  late Story story;
  bool isEditing = false;
  bool integratedWithJira = true;

  final jiraWorkItems = <JiraWorkItem>[
    JiraWorkItem(title: 'Create style', id: 'AC-1', link: 'https://apotec.atlassian.net/browse/AC-1'),
    JiraWorkItem(title: 'Create users', id: 'AC-2', link: 'https://apotec.atlassian.net/browse/AC-2'),
    JiraWorkItem(title: 'Delete users', id: 'AC-3', link: 'https://apotec.atlassian.net/browse/AC-3'),
    JiraWorkItem(title: 'Pagination', id: 'AC-4', link: 'https://apotec.atlassian.net/browse/AC-4'),
  ];

  @override
  void initState() {
    story = widget.story ?? Story(id: Uuid().v4(), description: '', status: StoryStatus.notStarted, votes: [], added: true, order: widget.nextOrder);
    isEditing = (widget.story?.added ?? false) || widget.story == null;

    _descriptionController.text = story.description;
    _searchController.value = _descriptionController.value;
    _urlController.text = story.url ?? '';

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void edit() {
    _descriptionController.text = story.description;
    _urlController.text = story.url ?? '';
    setState(() {
      isEditing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isEditing ? Colors.white : Colors.blueAccent,
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
                  Text(story.description, style: theme.textTheme.headlineLarge!.copyWith(color: Colors.white)),
                  if (story.url != null)
                    InkWell(
                      onTap: () async {
                        final Uri uri = Uri.parse(widget.story!.url!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not launch ${widget.story!.url!}';
                        }
                      },
                      child: Text(
                        widget.story!.url!,
                        style: TextStyle(
                          color: Colors.transparent,
                          shadows: [Shadow(color: Colors.white, offset: Offset(0, -3))],

                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                          decorationThickness: 1,
                          decorationStyle: TextDecorationStyle.solid,
                        ),
                      ),
                    ),
                ],
                if (isEditing) ...[
                  integratedWithJira
                      ? SearchViewTheme(
                        data: SearchViewThemeData(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.grey.shade50,
                          dividerColor: Colors.blueGrey.shade200,
                          headerHeight: 46,
                        ),
                        child: SearchBarTheme(
                          data: SearchBarThemeData(
                            hintStyle: WidgetStateProperty.all(theme.textTheme.bodyLarge!.copyWith(color: Colors.grey)),
                            backgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
                            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            elevation: WidgetStateProperty.all(0),
                            side: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.focused)) {
                                return const BorderSide(color: Colors.blueAccent, width: 2.0);
                              }
                              return BorderSide(color: Colors.blueGrey.shade200);
                            }),
                            //overlayColor: WidgetStateProperty.all(Colors.grey.shade50),
                          ),
                          child: SearchAnchor.bar(
                            searchController: _searchController,
                            barHintText: 'Story title',
                            barBackgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
                            barOverlayColor: WidgetStateProperty.all(Colors.transparent),
                            barLeading: const Icon(Icons.search),
                            barTrailing: [],
                            constraints: BoxConstraints(minHeight: 46),
                            suggestionsBuilder: (context, controller) {
                              final items = jiraWorkItems.where((t) => t.title.toLowerCase().contains(controller.value.text.toLowerCase()));
                              return items.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: ListTile(
                                    title: Text(t.title),
                                    onTap: () {
                                      controller.text = t.title;
                                      _descriptionController.text = t.title;
                                      controller.closeView(t.title);
                                    },
                                  ),
                                ),
                              );
                            },
                            onChanged: (value) {
                              _descriptionController.text = value;
                            },
                          ),
                        ),
                      )
                      : TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Story title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.text,
                        validator:
                            integratedWithJira
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          elevation: 5,
                        ),
                        child: Text('Update'),
                        onPressed: () {
                          story.description = _descriptionController.value.text;
                          story.url = _urlController.value.text;
                          story.added = false;
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
                    PopupMenuItem(onTap: edit, child: Row(spacing: 5, children: [Icon(Icons.edit), Text('Edit')])),
                    PopupMenuItem(onTap: widget.onDelete, child: Row(spacing: 5, children: [Icon(Icons.delete_outline, color: Colors.red), Text('Delete')])),
                    if (widget.onMoveUp != null)
                      PopupMenuItem(onTap: widget.onMoveUp, child: Row(spacing: 5, children: [Icon(Icons.move_up_outlined, color: Colors.blueAccent), Text('Move up')])),
                    if (widget.onMoveDown != null)
                      PopupMenuItem(onTap: widget.onMoveDown, child: Row(spacing: 5, children: [Icon(Icons.move_down_outlined, color: Colors.blueAccent), Text('Move down')])),
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
