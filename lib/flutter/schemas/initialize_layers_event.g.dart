// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initialize_layers_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitializeLayersEvent _$InitializeLayersEventFromJson(
        Map<String, dynamic> json) =>
    InitializeLayersEvent(
      (json['categoryList'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$InitializeLayersEventToJson(
        InitializeLayersEvent instance) =>
    <String, dynamic>{
      'categoryList': instance.categoryList,
    };
