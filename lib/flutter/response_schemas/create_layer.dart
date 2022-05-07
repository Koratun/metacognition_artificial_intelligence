import 'package:json_annotation/json_annotation.dart';

part 'create_layer.g.dart';

@JsonSerializable()
class CreateLayer {
	CreateLayer(this.layer, );

	String layer;

	factory CreateLayer.fromJson(Map<String, dynamic> json) => _$CreateLayerFromJson(json);

	Map<String, dynamic> toJson() => _$CreateLayerToJson(this);
}
