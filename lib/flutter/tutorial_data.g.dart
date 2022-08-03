// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TutorialData _$TutorialDataFromJson(Map<String, dynamic> json) => TutorialData(
      json['title'] as String,
      json['shortId'] as String,
      $enumDecode(_$ItemTypeEnumMap, json['displayItemType']),
      json['displayData'] as String,
      json['displayColor'] as String,
      (json['meat'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => TutorialItem.fromJson(e as Map<String, dynamic>))
              .toList())
          .toList(),
    );

Map<String, dynamic> _$TutorialDataToJson(TutorialData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'shortId': instance.shortId,
      'displayItemType': _$ItemTypeEnumMap[instance.displayItemType],
      'displayData': instance.displayData,
      'displayColor': instance.displayColor,
      'meat': instance.meat,
    };

const _$ItemTypeEnumMap = {
  ItemType.text: 'text',
  ItemType.icon: 'icon',
  ItemType.image: 'image',
};

TutorialItem _$TutorialItemFromJson(Map<String, dynamic> json) => TutorialItem(
      $enumDecode(_$ItemTypeEnumMap, json['type']),
      (json['data'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TutorialItemToJson(TutorialItem instance) =>
    <String, dynamic>{
      'type': _$ItemTypeEnumMap[instance.type],
      'data': instance.data,
    };
