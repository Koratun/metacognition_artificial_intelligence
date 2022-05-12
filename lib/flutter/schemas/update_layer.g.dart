// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLayer _$UpdateLayerFromJson(Map<String, dynamic> json) => UpdateLayer(
      json['layer'] as String,
      json['id'] as String,
      Map<String, String>.from(json['settings'] as Map),
    );

Map<String, dynamic> _$UpdateLayerToJson(UpdateLayer instance) =>
    <String, dynamic>{
      'layer': instance.layer,
      'id': instance.id,
      'settings': instance.settings,
    };
