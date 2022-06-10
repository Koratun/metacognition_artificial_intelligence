// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compile_success_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompileSuccessResponse _$CompileSuccessResponseFromJson(
        Map<String, dynamic> json) =>
    CompileSuccessResponse(
      json['pyFile'] as String,
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$CompileSuccessResponseToJson(
        CompileSuccessResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'pyFile': instance.pyFile,
    };
