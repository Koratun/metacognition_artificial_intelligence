// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_connection_limits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeConnectionLimits _$NodeConnectionLimitsFromJson(
        Map<String, dynamic> json) =>
    NodeConnectionLimits(
      json['min_upstream'] as String,
      json['max_upstream'] as String,
      json['min_downstream'] as String,
      json['max_downstream'] as String,
    );

Map<String, dynamic> _$NodeConnectionLimitsToJson(
        NodeConnectionLimits instance) =>
    <String, dynamic>{
      'min_upstream': instance.minUpstream,
      'max_upstream': instance.maxUpstream,
      'min_downstream': instance.minDownstream,
      'max_downstream': instance.maxDownstream,
    };
