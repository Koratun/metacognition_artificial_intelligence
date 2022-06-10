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
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$CompileErrorResponseToJson(
        CompileErrorResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'nodeId': instance.nodeId,
      'reason': _$CompileErrorReasonEnumMap[instance.reason],
      'errors': instance.errors,
    };

const _$CompileErrorReasonEnumMap = {
  CompileErrorReason.upstreamNodeCount: 'upstreamNodeCount',
  CompileErrorReason.downstreamNodeCount: 'downstreamNodeCount',
  CompileErrorReason.settingsValidation: 'settingsValidation',
  CompileErrorReason.compilationValidation: 'compilationValidation',
  CompileErrorReason.inputMissing: 'inputMissing',
  CompileErrorReason.disjointedGraph: 'disjointedGraph',
};
