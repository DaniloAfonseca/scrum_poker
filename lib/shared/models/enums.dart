import 'package:flutter/material.dart';

enum RoomStatus { notStarted, started, ended }

const $RoomStatusEnumMap = {RoomStatus.notStarted: 'notStarted', RoomStatus.started: 'started', RoomStatus.ended: 'ended'};

enum StoryStatus { notStarted, started, skipped, voted, ended }

const $StoryStatusEnumMap = {
  StoryStatus.notStarted: 'notStarted',
  StoryStatus.started: 'started',
  StoryStatus.skipped: 'skipped',
  StoryStatus.voted: 'voted',
  StoryStatus.ended: 'ended',
};

enum StoryType {
  workItem('Work item', Icons.work_outlined, Colors.blueAccent),
  bug('Bug', Icons.bug_report_outlined, Colors.redAccent),
  others('Others');

  const StoryType(this.description, [this.icon, this.color]);
  final String description;
  final IconData? icon;
  final Color? color;
}

enum VoteEnum {
  zero('0', 0),
  half('½', 0.5),
  one('1', 1),
  two('2', 2),
  three('3', 3),
  five('5', 5),
  eight('8', 8),
  thirteen('13', 13),
  twenty('20', 20),
  forty('40', 40),
  oneHundred('100', 100),
  questionMark('?'),
  infinity('∞'),
  coffee('coffee');

  const VoteEnum(this.label, [this.value]);

  final double? value;
  final String label;
}
