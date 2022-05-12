// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compile_error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompileErrorResponse _$CompileErrorResponseFromJson(
        Map<String, dynamic> json) =>
    CompileErrorResponse(
      json['nodeId'] as String,
      $enumDecode(_$CompileErrorReasonEnumMap, json['reason']),
      json['errors'] as String,
    );

Map<String, dynamic> _$CompileErrorResponseToJson(
        CompileErrorResponse instance) =>
    <String, dynamic>{
      'nodeId': instance.nodeId,
      'reason': _$CompileErrorReasonEnumMap[instance.reason],
      'errors': instance.errors,
    };

const _$CompileErrorReasonEnumMap = {
  CompileErrorReason.upstreamNodeCount: 'upstreamNodeCount',
  CompileErrorReason.settingsValidation: 'settingsValidation',
  CompileErrorReason.inputMissing: 'inputMissing',
  CompileErrorReason.disjointedGraph: 'disjointedGraph',
};
