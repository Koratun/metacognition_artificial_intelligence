// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteNode _$DeleteNodeFromJson(Map<String, dynamic> json) => DeleteNode(
      json['nodeId'] as String,
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$DeleteNodeToJson(DeleteNode instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'nodeId': instance.nodeId,
    };
