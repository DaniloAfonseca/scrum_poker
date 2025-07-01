// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => $checkedCreate('Room', json, ($checkedConvert) {
  final val = Room(
    name: $checkedConvert('name', (v) => v as String?),
    id: $checkedConvert('id', (v) => v as String?),
    dateAdded: $checkedConvert('dateAdded', (v) => v == null ? null : DateTime.parse(v as String)),
    dateDeleted: $checkedConvert('dateDeleted', (v) => v == null ? null : DateTime.parse(v as String)),
    stories: $checkedConvert('stories', (v) => (v as List<dynamic>).map((e) => Story.fromJson(e as Map<String, dynamic>)).toList()),
    cardsToUse: $checkedConvert('cardsToUse', (v) => (v as List<dynamic>).map((e) => $enumDecode(_$VoteEnumEnumMap, e)).toList()),
    userId: $checkedConvert('userId', (v) => v as String),
    status: $checkedConvert('status', (v) => $enumDecode(_$RoomStatusEnumMap, v)),
  );
  return val;
});

const _$VoteEnumEnumMap = {
  VoteEnum.zero: 'zero',
  VoteEnum.half: 'half',
  VoteEnum.one: 'one',
  VoteEnum.two: 'two',
  VoteEnum.three: 'three',
  VoteEnum.five: 'five',
  VoteEnum.eight: 'eight',
  VoteEnum.thirteen: 'thirteen',
  VoteEnum.twenty: 'twenty',
  VoteEnum.forty: 'forty',
  VoteEnum.oneHundred: 'oneHundred',
  VoteEnum.questionMark: 'questionMark',
  VoteEnum.infinity: 'infinity',
  VoteEnum.coffee: 'coffee',
};

const _$RoomStatusEnumMap = {RoomStatus.notStarted: 'notStarted', RoomStatus.started: 'started', RoomStatus.ended: 'ended'};
