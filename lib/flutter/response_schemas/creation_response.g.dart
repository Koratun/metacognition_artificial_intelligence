// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreationResponse _$CreationResponseFromJson(Map<String, dynamic> json) =>
    CreationResponse(
      json['node_id'] as String,
      (json['layer_settings'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      NodeConnectionLimits.fromJson(
          json['node_connection_limits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreationResponseToJson(CreationResponse instance) =>
    <String, dynamic>{
      'node_id': instance.nodeId,
      'layer_settings': instance.layerSettings,
      'node_connection_limits': instance.nodeConnectionLimits,
    };
