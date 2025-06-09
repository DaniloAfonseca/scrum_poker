import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';

part 'vote.g.dart';

@JsonSerializable()
class Vote {
  String voter;
  VoteEnum value;

  Vote({required this.voter, required this.value});
  factory Vote.fromJson(Map<String, dynamic> json) => _$VoteFromJson(json);
  Map<String, dynamic> toJson() => _$VoteToJson(this);
}
