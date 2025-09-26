import 'package:scrum_poker/shared/models/enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

@JsonSerializable(createToJson: false, includeIfNull: false)
class Room {
  String? name;
  String id;
  DateTime? dateAdded;
  DateTime? dateDeleted;
  final List<VoteEnum> cardsToUse;
  String userId;
  RoomStatus status;
  bool isDeleted;

  Room({this.name, required this.id, this.dateAdded, this.dateDeleted, required this.cardsToUse, required this.userId, required this.status, this.isDeleted = false});

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'id': id,
    if (dateAdded?.toIso8601String() case final value?) 'dateAdded': value,
    if (dateDeleted?.toIso8601String() case final value?) 'dateDeleted': value,
    'cardsToUse': cardsToUse.map((card) => _$VoteEnumEnumMap[card]!),
    'userId': userId,
    'status': _$RoomStatusEnumMap[status],
    'isDeleted': isDeleted,
  };
}
