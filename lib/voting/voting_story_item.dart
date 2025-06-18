import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/text_tag.dart';

class VotingStoryItem extends StatelessWidget {
  final ValueNotifier<Story?> currentStory;
  final Story story;
  final Function()? deletedChanged;
  final Function()? moveUp;
  final Function()? moveDown;
  final Function()? skipped;
  final bool canEdit;
  const VotingStoryItem({super.key, required this.currentStory, required this.story, this.deletedChanged, this.moveUp, this.moveDown, this.skipped, this.canEdit = false});

  @override
  Widget build(BuildContext context) {
    final menuKey = GlobalKey();
    return canEdit
        ? Container(
          decoration:
              currentStory.value?.description == story.description ? BoxDecoration(color: Colors.grey[100], border: Border(left: BorderSide(color: Colors.red, width: 2))) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), alignment: Alignment.centerLeft, height: 50, child: Text(story.description))),
              IconButton(
                key: menuKey,
                onPressed: () {
                  RenderBox box = menuKey.currentContext!.findRenderObject() as RenderBox;
                  Offset position = box.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    items: [
                      PopupMenuItem(onTap: skipped, child: Row(spacing: 5, children: [Icon(Icons.skip_next_outlined, color: Colors.blueAccent), Text('Skip')])),
                      if (moveUp != null)
                        PopupMenuItem(
                          child: Row(spacing: 5, children: [Icon(Icons.move_up_outlined, color: Colors.blueAccent), Text('Move up')]),
                          onTap: () async {
                            moveUp!();
                          },
                        ),
                      if (moveDown != null)
                        PopupMenuItem(
                          child: Row(spacing: 5, children: [Icon(Icons.move_down_outlined, color: Colors.blueAccent), Text('Move down')]),
                          onTap: () async {
                            moveDown!();
                          },
                        ),
                      if (deletedChanged != null)
                        PopupMenuItem(
                          child: Row(spacing: 5, children: [Icon(Icons.delete_outline, color: Colors.red), Text('Delete')]),
                          onTap: () async {
                            deletedChanged!();
                          },
                        ),
                    ],
                    position: RelativeRect.fromLTRB(position.dx - 120, position.dy + 40, position.dx, position.dy),
                  );
                },
                icon: Icon(Icons.more_vert),
              ),
            ],
          ),
        )
        : Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.centerLeft,
          height: 50,
          child: Row(
            spacing: 10,
            children: [Text(story.description), TextTag(text: 'Skipped', backgroundColor: Colors.red, foreColor: Colors.white, display: story.status == StatusEnum.skipped)],
          ),
        );
  }
}
