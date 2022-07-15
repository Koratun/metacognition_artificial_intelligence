// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationResponse _$ValidationResponseFromJson(Map<String, dynamic> json) =>
    ValidationResponse(
      (json['errors'] as List<dynamic>?)
          ?.map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$ValidationResponseToJson(ValidationResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'errors': instance.errors,
    };
