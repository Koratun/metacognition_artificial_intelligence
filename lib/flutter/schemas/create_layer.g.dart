// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLayer _$CreateLayerFromJson(Map<String, dynamic> json) => CreateLayer(
      json['layer'] as String,
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$CreateLayerToJson(CreateLayer instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'layer': instance.layer,
    };
