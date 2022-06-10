import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'initialize_layers_event.g.dart';

@JsonSerializable()
class InitializeLayersEvent extends Schema {
	InitializeLayersEvent(this.categoryList, );

	Map<String, List<String>> categoryList;

	factory InitializeLayersEvent.fromJson(Map<String, dynamic> json) => _$InitializeLayersEventFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$InitializeLayersEventToJson(this);
}
