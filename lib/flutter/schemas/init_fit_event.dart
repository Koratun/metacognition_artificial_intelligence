import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'init_fit_event.g.dart';

@JsonSerializable()
class InitFitEvent extends Schema {
	InitFitEvent(this.nodeId, this.settings, );

	String nodeId;
	Map<String, String> settings;

	factory InitFitEvent.fromJson(Map<String, dynamic> json) => _$InitFitEventFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$InitFitEventToJson(this);
}
