import 'package:json_annotation/json_annotation.dart';
import 'node_connection_limits.dart';

part 'creation_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CreationResponse {
	CreationResponse(this.nodeId, this.layerSettings, this.nodeConnectionLimits, );

	String nodeId;
	List<String> layerSettings;
	NodeConnectionLimits nodeConnectionLimits;

	factory CreationResponse.fromJson(Map<String, dynamic> json) => _$CreationResponseFromJson(json);

	Map<String, dynamic> toJson() => _$CreationResponseToJson(this);
}
