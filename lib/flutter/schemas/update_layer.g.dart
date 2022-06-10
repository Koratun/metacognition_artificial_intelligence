// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLayer _$UpdateLayerFromJson(Map<String, dynamic> json) => UpdateLayer(
      json['layer'] as String,
      json['id'] as String,
      Map<String, String>.from(json['settings'] as Map),
    )..requestId = json['requestId'] as String;

Map<String, dynamic> _$UpdateLayerToJson(UpdateLayer instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'layer': instance.layer,
      'id': instance.id,
      'settings': instance.settings,
    };
