// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_connection_limits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeConnectionLimits _$NodeConnectionLimitsFromJson(
        Map<String, dynamic> json) =>
    NodeConnectionLimits(
      json['minUpstream'] as int,
      json['maxUpstream'] as String,
      json['minDownstream'] as int,
      json['maxDownstream'] as String,
    );

Map<String, dynamic> _$NodeConnectionLimitsToJson(
        NodeConnectionLimits instance) =>
    <String, dynamic>{
      'minUpstream': instance.minUpstream,
      'maxUpstream': instance.maxUpstream,
      'minDownstream': instance.minDownstream,
      'maxDownstream': instance.maxDownstream,
    };
