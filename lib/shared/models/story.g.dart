// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Story', json, ($checkedConvert) {
      final val = Story(
        description: $checkedConvert('description', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String?),
        vote: $checkedConvert('vote', (v) => (v as num?)?.toInt()),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$StoryStatusEnumEnumMap, v),
        ),
        votes: $checkedConvert(
          'votes',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => Vote.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
        added: $checkedConvert('added', (v) => v as bool? ?? false),
      );
      return val;
    });

const _$StoryStatusEnumEnumMap = {
  StoryStatusEnum.newStory: 'newStory',
  StoryStatusEnum.voting: 'voting',
  StoryStatusEnum.voted: 'voted',
};
