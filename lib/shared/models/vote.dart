import 'package:json_annotation/json_annotation.dart';
import 'package:scrum_poker/shared/models/enums.dart';

part 'vote.g.dart';

@JsonSerializable(includeIfNull: false)
class Vote {
  String userName;
  String userId;
  VoteEnum value;

  Vote({required this.userName, required this.userId, required this.value});
  factory Vote.fromJson(Map<String, dynamic> json) => _$VoteFromJson(json);
  Map<String, dynamic> toJson() => _$VoteToJson(this);
}
