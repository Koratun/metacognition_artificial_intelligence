// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'init_fit_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitFitEvent _$InitFitEventFromJson(Map<String, dynamic> json) => InitFitEvent(
      json['nodeId'] as String,
      Map<String, String>.from(json['settings'] as Map),
    );

Map<String, dynamic> _$InitFitEventToJson(InitFitEvent instance) =>
    <String, dynamic>{
      'nodeId': instance.nodeId,
      'settings': instance.settings,
    };
