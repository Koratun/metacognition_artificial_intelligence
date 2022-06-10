// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection _$ConnectionFromJson(Map<String, dynamic> json) => Connection(
      json['sourceId'] as String,
      json['destId'] as String,
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$ConnectionToJson(Connection instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'sourceId': instance.sourceId,
      'destId': instance.destId,
    };
