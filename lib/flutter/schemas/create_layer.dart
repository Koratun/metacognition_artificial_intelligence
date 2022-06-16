import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'create_layer.g.dart';

@JsonSerializable()
class CreateLayer implements Schema {
	CreateLayer(this.layer, );

	String layer;

	factory CreateLayer.fromJson(Map<String, dynamic> json) => _$CreateLayerFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$CreateLayerToJson(this);
}
