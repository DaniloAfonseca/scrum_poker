import 'package:scrum_poker/shared/models/enums.dart';

class Vote {
  String voter;
  VoteEnum value;

  Vote({required this.voter, required this.value});
}
