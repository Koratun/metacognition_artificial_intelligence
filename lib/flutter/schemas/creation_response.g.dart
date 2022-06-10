// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreationResponse _$CreationResponseFromJson(Map<String, dynamic> json) =>
    CreationResponse(
      json['nodeId'] as String,
      (json['layerSettings'] as List<dynamic>).map((e) => e as String).toList(),
      NodeConnectionLimits.fromJson(
          json['nodeConnectionLimits'] as Map<String, dynamic>),
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$CreationResponseToJson(CreationResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'nodeId': instance.nodeId,
      'layerSettings': instance.layerSettings,
      'nodeConnectionLimits': instance.nodeConnectionLimits,
    };
