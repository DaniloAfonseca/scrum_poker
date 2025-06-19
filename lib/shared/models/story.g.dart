// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Story', json, ($checkedConvert) {
      final val = Story(
        id: $checkedConvert('id', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String?),
        estimate: $checkedConvert('estimate', (v) => (v as num?)?.toInt()),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$StatusEnumEnumMap, v),
        ),
        votes: $checkedConvert(
          'votes',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => Vote.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
        revisedEstimate: $checkedConvert(
          'revisedEstimate',
          (v) => (v as num?)?.toInt(),
        ),
        order: $checkedConvert('order', (v) => (v as num).toInt()),
      );
      return val;
    });

const _$StatusEnumEnumMap = {
  StatusEnum.notStarted: 'notStarted',
  StatusEnum.started: 'started',
  StatusEnum.skipped: 'skipped',
  StatusEnum.ended: 'ended',
};
