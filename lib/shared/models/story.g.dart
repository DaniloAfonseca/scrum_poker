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
          id: $checkedConvert('id', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String?),
          estimate: $checkedConvert('estimate', (v) => (v as num?)?.toDouble()),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$StoryStatusEnumMap, v)),
          votes: $checkedConvert(
              'votes',
              (v) => (v as List<dynamic>)
                  .map((e) => Vote.fromJson(e as Map<String, dynamic>))
                  .toList()),
          revisedEstimate:
              $checkedConvert('revisedEstimate', (v) => (v as num?)?.toInt()),
          order: $checkedConvert('order', (v) => (v as num).toInt()),
          currentStory:
              $checkedConvert('currentStory', (v) => v as bool? ?? false),
        );
        return val;
      },
    );

const _$StoryStatusEnumMap = {
  StoryStatus.notStarted: 'notStarted',
  StoryStatus.started: 'started',
  StoryStatus.skipped: 'skipped',
  StoryStatus.voted: 'voted',
  StoryStatus.ended: 'ended',
};
