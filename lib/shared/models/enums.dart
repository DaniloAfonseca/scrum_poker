import 'package:flutter/material.dart';

enum RoomStatus { notStarted, started, ended }

const $RoomStatusEnumMap = {RoomStatus.notStarted: 'notStarted', RoomStatus.started: 'started', RoomStatus.ended: 'ended'};

enum StoryStatus {
  notStarted(active: true),
  started(active: true),
  skipped,
  voted(active: true),
  ended;

  const StoryStatus({this.active = false});
  final bool active;
}

const $StoryStatusEnumMap = {
  StoryStatus.notStarted: 'notStarted',
  StoryStatus.started: 'started',
  StoryStatus.skipped: 'skipped',
  StoryStatus.voted: 'voted',
  StoryStatus.ended: 'ended',
};

enum StoryType {
  workItem('Work item', Icons.turned_in_not_outlined, Colors.green),
  bug('Bug', Icons.bug_report_outlined, Colors.red),
  others('Others');

  const StoryType(this.description, [this.icon, this.color]);
  final String description;
  final IconData? icon;
  final Color? color;
}

enum VoteEnum {
  zero(label: '0', value: 0),
  half(label: '½', value: 0.5),
  one(label: '1', value: 1),
  two(label: '2', value: 2),
  three(label: '3', value: 3),
  five(label: '5', value: 5),
  eight(label: '8', value: 8),
  thirteen(label: '13', value: 13),
  twenty(label: '20', value: 20),
  forty(label: '40', value: 40),
  oneHundred(label: '100', value: 100),
  questionMark(label: '?'),
  infinity(label: '∞'),
  coffee(label: 'coffee', icon: Icons.coffee);

  const VoteEnum({required this.label, this.value, this.icon});

  final double? value;
  final String label;
  final IconData? icon;
}
