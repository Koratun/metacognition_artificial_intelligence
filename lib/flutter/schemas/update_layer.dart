import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'update_layer.g.dart';

@JsonSerializable()
class UpdateLayer implements Schema {
	UpdateLayer(this.layer, this.id, this.settings, );

	String layer;
	String id;
	Map<String, String> settings;

	factory UpdateLayer.fromJson(Map<String, dynamic> json) => _$UpdateLayerFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$UpdateLayerToJson(this);
}
