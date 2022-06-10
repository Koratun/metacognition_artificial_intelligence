// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_exception_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GraphExceptionResponse _$GraphExceptionResponseFromJson(
        Map<String, dynamic> json) =>
    GraphExceptionResponse(
      json['error'] as String,
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$GraphExceptionResponseToJson(
        GraphExceptionResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'error': instance.error,
    };
