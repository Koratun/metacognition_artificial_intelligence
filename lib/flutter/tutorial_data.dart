import 'package:json_annotation/json_annotation.dart';

part 'tutorial_data.g.dart';

enum ItemType { text, icon, image }

@JsonSerializable()
class TutorialData {
  TutorialData(
    this.title,
    this.shortId,
    this.displayItemType,
    this.displayData,
    this.displayColor,
    this.meat,
  );

  String title;
  String shortId;
  // One of 'text', 'icon', or 'image'
  ItemType displayItemType;
  // text -> just the text: "AI"
  // icon -> hex code for IconData
  //    (e.g. IconData(0xf04b6, fontFamily: "MaterialIcons"))
  // image -> file path relative to root asset directory: "layer_tiles/Dense.png"
  String displayData;
  // Color to display item with in hex: 0xff ff ff ff -> A R G B
  String displayColor;

  // Each outer list is a different page of the tutorial
  // the inner list is the order to show different paragraphs or media in.
  List<List<TutorialItem>> meat;

  factory TutorialData.fromJson(Map<String, dynamic> json) =>
      _$TutorialDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TutorialDataToJson(this);
}

@JsonSerializable()
class TutorialItem {
  TutorialItem(this.type, this.data);

  ItemType type;
  List<String> data;

  factory TutorialItem.fromJson(Map<String, dynamic> json) =>
      _$TutorialItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TutorialItemToJson(this);
}
