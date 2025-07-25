import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/text_tag.dart';

class VotingListItem extends StatelessWidget {
  final Story? currentStory;
  final Story story;
  final FutureOr<void> Function()? onDelete;
  final FutureOr<void> Function()? onMoveUp;
  final FutureOr<void> Function()? onMoveDown;
  final FutureOr<void> Function()? onSkip;
  final FutureOr<void> Function()? onMoveToActive;
  final int? reorderIndex;
  const VotingListItem({
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
      contentPadding: const EdgeInsets.all(0),
      minVerticalPadding: 0,
      selectedTileColor: theme.primaryColor.withAlpha(50),
      selectedColor: theme.textTheme.bodyLarge?.color,
      selected: currentStory?.id == story.id,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      leading: reorderIndex == null || user == null
          ? null
          : Container(
              padding: const EdgeInsets.only(left: 5),
              height: 45,
              decoration: currentStory?.id == story.id
                  ? const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.red, width: 2)),
                    )
                  : null,
              child: ReorderableDragStartListener(index: reorderIndex!, child: const Icon(Icons.format_list_bulleted_sharp, size: 18)),
            ),
      title: Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (story.storyType != null) Icon(story.storyType!.icon, color: story.storyType!.color),
          Flexible(
            child: Row(
              spacing: 10,
              children: [
                if (user == null) const SizedBox(width: 10),
                if (story.url == null || story.url!.isEmpty) Flexible(child: Text(story.fullDescription, style: theme.textTheme.bodyLarge, softWrap: true)),
                if (story.url != null && story.url!.isNotEmpty)
                  Flexible(
                    child: Hyperlink(text: story.fullDescription, textStyle: theme.textTheme.bodyLarge, color: theme.textTheme.bodyLarge?.decorationColor, url: story.url!),
                  ),

                TextTag(text: 'Skipped', backgroundColor: Colors.red, foreColor: Colors.white, display: story.status == StoryStatus.skipped),
              ],
            ),
          ),
          if (story.estimate != null)
            Tooltip(
              message: 'Estimated story point',
              child: Container(
                color: theme.dividerColor,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                child: Text(story.estimate.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: theme.primaryColor)),
              ),
            ),

          if (story.revisedEstimate != null)
            Tooltip(
              message: 'Story points',
              child: Container(
                color: Colors.blueAccent,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                child: Text(story.revisedEstimate.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
              ),
            ),
        ],
      ),
      trailing: hasMenuItems
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
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(FontAwesomeIcons.arrowRotateLeft, color: Colors.blueAccent),
                            Text('Move to active'),
                          ],
                        ),
                      ),
                    if (onSkip != null)
                      PopupMenuItem(
                        onTap: onSkip,
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.skip_next_outlined, color: Colors.blueAccent),
                            Text('Skip'),
                          ],
                        ),
                      ),
                    if (onMoveUp != null)
                      PopupMenuItem(
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.move_up_outlined, color: Colors.blueAccent),
                            Text('Move up'),
                          ],
                        ),
                        onTap: () async {
                          onMoveUp!();
                        },
                      ),
                    if (onMoveDown != null)
                      PopupMenuItem(
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.move_down_outlined, color: Colors.blueAccent),
                            Text('Move down'),
                          ],
                        ),
                        onTap: () async {
                          onMoveDown!();
                        },
                      ),
                    if (onDelete != null) ...[
                      const PopupMenuItem(height: 1, enabled: false, child: Divider()),
                      PopupMenuItem(
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            Text('Delete'),
                          ],
                        ),
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
              icon: const Icon(Icons.more_vert),
            )
          : null,
    );
  }
}
