// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Story',
  json,
  ($checkedConvert) {
    final val = Story(
      userId: $checkedConvert('userId', (v) => v as String),
      roomId: $checkedConvert('roomId', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String?),
      estimate: $checkedConvert('estimate', (v) => (v as num?)?.toDouble()),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$StoryStatusEnumMap, v),
      ),
      revisedEstimate: $checkedConvert(
        'revisedEstimate',
        (v) => (v as num?)?.toDouble(),
      ),
      order: $checkedConvert('order', (v) => (v as num).toInt()),
      currentStory: $checkedConvert('currentStory', (v) => v as bool? ?? false),
      storyType: $checkedConvert(
        'storyType',
        (v) => $enumDecodeNullable(_$StoryTypeEnumMap, v),
      ),
      jiraKey: $checkedConvert('jiraKey', (v) => v as String?),
    );
    return val;
  },
);

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
  'userId': instance.userId,
  'roomId': instance.roomId,
  'id': instance.id,
  'description': instance.description,
  if (instance.url case final value?) 'url': value,
  if (instance.jiraKey case final value?) 'jiraKey': value,
  if (instance.estimate case final value?) 'estimate': value,
  'status': _$StoryStatusEnumMap[instance.status]!,
  if (instance.revisedEstimate case final value?) 'revisedEstimate': value,
  'order': instance.order,
  'currentStory': instance.currentStory,
  if (_$StoryTypeEnumMap[instance.storyType] case final value?)
    'storyType': value,
};

const _$StoryStatusEnumMap = {
  StoryStatus.notStarted: 'notStarted',
  StoryStatus.started: 'started',
  StoryStatus.skipped: 'skipped',
  StoryStatus.voted: 'voted',
  StoryStatus.ended: 'ended',
};

const _$StoryTypeEnumMap = {
  StoryType.workItem: 'workItem',
  StoryType.bug: 'bug',
  StoryType.others: 'others',
};
