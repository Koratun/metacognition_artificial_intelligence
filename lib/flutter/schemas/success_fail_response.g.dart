// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'success_fail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuccessFailResponse _$SuccessFailResponseFromJson(Map<String, dynamic> json) =>
    SuccessFailResponse(
      json['error'] as String?,
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$SuccessFailResponseToJson(
        SuccessFailResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'error': instance.error,
    };
