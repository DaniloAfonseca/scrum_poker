// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseResponse<T> _$BaseResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    $checkedCreate(
      'BaseResponse',
      json,
      ($checkedConvert) {
        final val = BaseResponse<T>(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
          data: $checkedConvert(
              'data', (v) => _$nullableGenericFromJson(v, fromJsonT)),
        );
        return val;
      },
    );

Map<String, dynamic> _$BaseResponseToJson<T>(
  BaseResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': _$nullableGenericToJson(instance.data, toJsonT),
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);
