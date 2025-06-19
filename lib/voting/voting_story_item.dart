import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/text_tag.dart';

class VotingStoryItem extends StatelessWidget {
  final ValueNotifier<Story?> currentStory;
  final Story story;
  final Function()? onDelete;
  final Function()? onMoveUp;
  final Function()? onMoveDown;
  final Function()? onSkip;
  final Function()? onMoveToActive;
  const VotingStoryItem({super.key, required this.currentStory, required this.story, this.onDelete, this.onMoveUp, this.onMoveDown, this.onSkip, this.onMoveToActive});

  @override
  Widget build(BuildContext context) {
    final menuKey = GlobalKey();
    final hasMenuItems = onMoveToActive != null || onSkip != null || onMoveUp != null || onMoveDown != null || onDelete != null;
    final theme = Theme.of(context);
    return Container(
      decoration:
          currentStory.value?.description == story.description ? BoxDecoration(color: Colors.grey[100], border: Border(left: BorderSide(color: Colors.red, width: 2))) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), alignment: Alignment.centerLeft, height: 50, child: Text(story.description)),
                TextTag(text: 'Skipped', backgroundColor: Colors.red, foreColor: Colors.white, display: story.status == StatusEnum.skipped),
              ],
            ),
          ),
          SizedBox(width: 120, child: Text(story.estimate == null ? '' : story.estimate.toString(), style: theme.textTheme.headlineSmall)),
          if (story.revisedEstimate != null)
            SizedBox(width: 120, child: Text(story.revisedEstimate == null ? '' : story.revisedEstimate.toString(), style: theme.textTheme.headlineSmall)),
          if (hasMenuItems)
            IconButton(
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
                  position: RelativeRect.fromLTRB(position.dx - 120, position.dy + 40, position.dx, position.dy),
                );
              },
              icon: Icon(Icons.more_vert),
            ),
        ],
      ),
    );
  }
}
