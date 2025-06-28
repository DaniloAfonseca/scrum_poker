import 'dart:ui';

import 'package:scrum_poker/shared/models/enums.dart';

class VoteResult {
  final VoteEnum vote; // e.g. '1', '3', '5', '?'
  int count; // number of users who voted for this
  Color? color;
  double? percentage;

  VoteResult({required this.vote, required this.count});
}
