// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compile_error_disjointed_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompileErrorDisjointedResponse _$CompileErrorDisjointedResponseFromJson(
        Map<String, dynamic> json) =>
    CompileErrorDisjointedResponse(
      (json['node_ids'] as List<dynamic>).map((e) => e as String).toList(),
      $enumDecode(_$CompileErrorReasonEnumMap, json['reason']),
      json['errors'] as String,
    );

Map<String, dynamic> _$CompileErrorDisjointedResponseToJson(
        CompileErrorDisjointedResponse instance) =>
    <String, dynamic>{
      'node_ids': instance.nodeIds,
      'reason': _$CompileErrorReasonEnumMap[instance.reason],
      'errors': instance.errors,
    };

const _$CompileErrorReasonEnumMap = {
  CompileErrorReason.upstreamNodeCount: 'upstreamNodeCount',
  CompileErrorReason.settingsValidation: 'settingsValidation',
  CompileErrorReason.inputMissing: 'inputMissing',
  CompileErrorReason.disjointedGraph: 'disjointedGraph',
};
