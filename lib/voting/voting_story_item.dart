import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/text_tag.dart';
import 'package:url_launcher/url_launcher.dart';

class VotingStoryItem extends StatelessWidget {
  final Story? currentStory;
  final Story story;
  final FutureOr<void> Function()? onDelete;
  final FutureOr<void> Function()? onMoveUp;
  final FutureOr<void> Function()? onMoveDown;
  final FutureOr<void> Function()? onSkip;
  final FutureOr<void> Function()? onMoveToActive;
  final int? reorderIndex;
  const VotingStoryItem({
    super.key,
    required this.currentStory,
    required this.story,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.onSkip,
    this.onMoveToActive,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final menuKey = GlobalKey();
    final hasMenuItems = (onMoveToActive != null || onSkip != null || onMoveUp != null || onMoveDown != null || onDelete != null) && user != null;
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      minVerticalPadding: 0,
      selectedTileColor: Colors.grey[200],
      selectedColor: Colors.black,
      selected: currentStory?.id == story.id,
      leading:
          reorderIndex == null || user == null
              ? null
              : Container(
                padding: EdgeInsets.only(left: 10),
                height: 30,
                decoration: currentStory?.id == story.id ? BoxDecoration(border: Border(left: BorderSide(color: Colors.red, width: 2))) : null,
                child: ReorderableDragStartListener(index: reorderIndex!, child: const Icon(Icons.drag_handle_outlined)),
              ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              children: [
                if (user == null) SizedBox(width: 10),
                if (story.url == null || story.url!.isEmpty) Text(story.description, style: theme.textTheme.bodyLarge),
                if (story.url != null && story.url!.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final Uri uri = Uri.parse(story.url!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Could not launch ${story.url!}';
                      }
                    },
                    child: Text(
                      story.description,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: Colors.transparent,
                        shadows: [Shadow(color: Colors.black, offset: Offset(0, -3))],

                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                        decorationThickness: 1,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                  ),
                TextTag(text: 'Skipped', backgroundColor: Colors.red, foreColor: Colors.white, display: story.status == StoryStatus.skipped),
              ],
            ),
          ),
          SizedBox(width: 120, child: story.estimate == null ? null : Tooltip(message: 'Calculated estimated', child: Text(story.estimate.toString()))),
          SizedBox(width: 120, child: story.revisedEstimate == null ? null : Tooltip(message: 'Real estimated', child: Text(story.revisedEstimate.toString()))),
        ],
      ),
      trailing:
          hasMenuItems
              ? IconButton(
                key: menuKey,
                onPressed: () {
                  RenderBox box = menuKey.currentContext!.findRenderObject() as RenderBox;
                  Offset position = box.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    items: [
                      if (onMoveToActive != null)
                        PopupMenuItem(
                          onTap: onMoveToActive,
                          child: Row(spacing: 5, children: [Icon(FontAwesomeIcons.arrowRotateLeft, color: Colors.blueAccent), Text('Move to active')]),
                        ),
                      if (onSkip != null) PopupMenuItem(onTap: onSkip, child: Row(spacing: 5, children: [Icon(Icons.skip_next_outlined, color: Colors.blueAccent), Text('Skip')])),
                      if (onMoveUp != null)
                        PopupMenuItem(
                          child: Row(spacing: 5, children: [Icon(Icons.move_up_outlined, color: Colors.blueAccent), Text('Move up')]),
                          onTap: () async {
                            onMoveUp!();
                          },
                        ),
                      if (onMoveDown != null)
                        PopupMenuItem(
                          child: Row(spacing: 5, children: [Icon(Icons.move_down_outlined, color: Colors.blueAccent), Text('Move down')]),
                          onTap: () async {
                            onMoveDown!();
                          },
                        ),
                      if (onDelete != null) ...[
                        PopupMenuItem(height: 1, enabled: false, child: Divider()),
                        PopupMenuItem(
                          child: Row(spacing: 5, children: [Icon(Icons.delete_outline, color: Colors.red), Text('Delete')]),
                          onTap: () async {
                            onDelete!();
                          },
                        ),
                      ],
                    ],
                    position: RelativeRect.fromLTRB(
                      position.dx -
                          (onMoveToActive != null
                              ? 185
                              : onMoveDown != null
                              ? 165
                              : 110),
                      position.dy,
                      position.dx,
                      position.dy,
                    ),
                  );
                },
                icon: Icon(Icons.more_vert),
              )
              : null,
    );
  }
}
