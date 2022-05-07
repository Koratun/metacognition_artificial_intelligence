// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartupResponse _$StartupResponseFromJson(Map<String, dynamic> json) =>
    StartupResponse(
      (json['category_list'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$StartupResponseToJson(StartupResponse instance) =>
    <String, dynamic>{
      'category_list': instance.categoryList,
    };
