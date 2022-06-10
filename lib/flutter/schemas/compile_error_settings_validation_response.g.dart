// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compile_error_settings_validation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompileErrorSettingsValidationResponse
    _$CompileErrorSettingsValidationResponseFromJson(
            Map<String, dynamic> json) =>
        CompileErrorSettingsValidationResponse(
          (json['errors'] as List<dynamic>)
              .map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
              .toList(),
          json['nodeId'] as String,
          $enumDecode(_$CompileErrorReasonEnumMap, json['reason']),
        )..requestId = json['requestId'] as String;

Map<String, dynamic> _$CompileErrorSettingsValidationResponseToJson(
        CompileErrorSettingsValidationResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'errors': instance.errors,
      'nodeId': instance.nodeId,
      'reason': _$CompileErrorReasonEnumMap[instance.reason],
    };

const _$CompileErrorReasonEnumMap = {
  CompileErrorReason.upstreamNodeCount: 'upstreamNodeCount',
  CompileErrorReason.downstreamNodeCount: 'downstreamNodeCount',
  CompileErrorReason.settingsValidation: 'settingsValidation',
  CompileErrorReason.compilationValidation: 'compilationValidation',
  CompileErrorReason.inputMissing: 'inputMissing',
  CompileErrorReason.disjointedGraph: 'disjointedGraph',
};
