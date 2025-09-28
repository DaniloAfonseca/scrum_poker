import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/text_tag.dart';

class VotingListItem extends StatefulWidget {
  final Story? currentStory;
  final Story story;
  final FutureOr<void> Function()? onDelete;
  final FutureOr<void> Function()? onMoveUp;
  final FutureOr<void> Function()? onMoveDown;
  final FutureOr<void> Function()? onSkip;
  final FutureOr<void> Function()? onMoveToActive;
  final int? reorderIndex;
  final ValueNotifier<bool>? isReordering;
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
    this.isReordering,
  });

  @override
  State<VotingListItem> createState() => _VotingListItemState();
}

class _VotingListItemState extends State<VotingListItem> {
  bool _isHovered = false;

  ValueNotifier<bool> _isReordering = ValueNotifier<bool>(false);

  @override
  void initState() {
    if (widget.isReordering != null) {
      _isReordering = widget.isReordering!;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final menuKey = GlobalKey();
    final hasMenuItems =
        (widget.onMoveToActive != null || widget.onSkip != null || widget.onMoveUp != null || widget.onMoveDown != null || widget.onDelete != null) && user != null;
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (event) {
        setState(() {
          _isHovered = false;
        });
      },
      child: ListTile(
        tileColor: _isHovered ? theme.hoverColor : null,
        contentPadding: const EdgeInsets.all(0),
        minVerticalPadding: 0,
        selectedTileColor: _isHovered ? Color.lerp(theme.hoverColor, theme.primaryColor.withAlpha(50), 0.2) : theme.primaryColor.withAlpha(50),
        selectedColor: theme.textTheme.bodyLarge?.color,
        selected: widget.currentStory?.id == widget.story.id,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        leading: widget.reorderIndex == null || user == null
            ? null
            : ValueListenableBuilder(
                valueListenable: _isReordering,
                builder: (context, value, child) {
                  return MouseRegion(
                    cursor: value ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                    child: Container(
                      padding: const EdgeInsets.only(left: 5),
                      height: 45,
                      decoration: widget.currentStory?.id == widget.story.id
                          ? const BoxDecoration(
                              border: Border(left: BorderSide(color: Colors.red, width: 2)),
                            )
                          : null,
                      child: ReorderableDragStartListener(index: widget.reorderIndex!, child: const Icon(Icons.format_list_bulleted_sharp, size: 18)),
                    ),
                  );
                },
              ),
        title: Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.story.storyType != null) Icon(widget.story.storyType!.icon, color: widget.story.storyType!.color),
            Flexible(
              child: Row(
                spacing: 10,
                children: [
                  if (user == null) const SizedBox(width: 10),
                  if (widget.story.url == null || widget.story.url!.isEmpty) Flexible(child: Text(widget.story.fullDescription, style: theme.textTheme.bodyLarge, softWrap: true)),
                  if (widget.story.url != null && widget.story.url!.isNotEmpty)
                    Flexible(
                      child: Hyperlink(
                        text: widget.story.fullDescription,
                        textStyle: theme.textTheme.bodyLarge,
                        color: theme.textTheme.bodyLarge?.decorationColor,
                        url: widget.story.url!,
                      ),
                    ),

                  TextTag(text: 'Skipped', backgroundColor: Colors.red, foreColor: Colors.white, display: widget.story.status == StoryStatus.skipped),
                ],
              ),
            ),
            if (widget.story.estimate != null)
              Tooltip(
                message: 'Estimated story point',
                child: Container(
                  color: theme.dividerColor,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  child: Text(widget.story.estimate.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: theme.primaryColor)),
                ),
              ),

            if (widget.story.revisedEstimate != null)
              Tooltip(
                message: 'Story points',
                child: Container(
                  color: Colors.blueAccent,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  child: Text(widget.story.revisedEstimate.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white)),
                ),
              ),
            const SizedBox(width: 5),
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
                      if (widget.onMoveToActive != null)
                        PopupMenuItem(
                          onTap: widget.onMoveToActive,
                          child: const Row(
                            spacing: 5,
                            children: [
                              Icon(FontAwesomeIcons.arrowRotateLeft, color: Colors.blueAccent),
                              Text('Move to active'),
                            ],
                          ),
                        ),
                      if (widget.onSkip != null)
                        PopupMenuItem(
                          onTap: widget.onSkip,
                          child: const Row(
                            spacing: 5,
                            children: [
                              Icon(Icons.skip_next_outlined, color: Colors.blueAccent),
                              Text('Skip'),
                            ],
                          ),
                        ),
                      if (widget.onMoveUp != null)
                        PopupMenuItem(
                          child: const Row(
                            spacing: 5,
                            children: [
                              Icon(Icons.move_up_outlined, color: Colors.blueAccent),
                              Text('Move up'),
                            ],
                          ),
                          onTap: () async {
                            widget.onMoveUp!();
                          },
                        ),
                      if (widget.onMoveDown != null)
                        PopupMenuItem(
                          child: const Row(
                            spacing: 5,
                            children: [
                              Icon(Icons.move_down_outlined, color: Colors.blueAccent),
                              Text('Move down'),
                            ],
                          ),
                          onTap: () async {
                            widget.onMoveDown!();
                          },
                        ),
                      if (widget.onDelete != null) ...[
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
                            widget.onDelete!();
                          },
                        ),
                      ],
                    ],
                    position: RelativeRect.fromLTRB(
                      position.dx -
                          (widget.onMoveToActive != null
                              ? 185
                              : widget.onMoveDown != null
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
      ),
    );
  }
}
