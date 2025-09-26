// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vote _$VoteFromJson(Map<String, dynamic> json) => $checkedCreate('Vote', json, (
  $checkedConvert,
) {
  final val = Vote(
    roomId: $checkedConvert('roomId', (v) => v as String),
    storyId: $checkedConvert('storyId', (v) => v as String),
    storyStatus: $checkedConvert(
      'storyStatus',
      (v) => $enumDecode(_$StoryStatusEnumMap, v),
    ),
    userName: $checkedConvert('userName', (v) => v as String),
    userId: $checkedConvert('userId', (v) => v as String),
    value: $checkedConvert('value', (v) => $enumDecode(_$VoteEnumEnumMap, v)),
  );
  return val;
});

Map<String, dynamic> _$VoteToJson(Vote instance) => <String, dynamic>{
  'roomId': instance.roomId,
  'storyId': instance.storyId,
  'storyStatus': _$StoryStatusEnumMap[instance.storyStatus]!,
  'userId': instance.userId,
  'userName': instance.userName,
  'value': _$VoteEnumEnumMap[instance.value]!,
};

const _$StoryStatusEnumMap = {
  StoryStatus.notStarted: 'notStarted',
  StoryStatus.started: 'started',
  StoryStatus.skipped: 'skipped',
  StoryStatus.voted: 'voted',
  StoryStatus.ended: 'ended',
};

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
