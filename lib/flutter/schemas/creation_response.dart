import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';
import 'node_connection_limits.dart';

part 'creation_response.g.dart';

@JsonSerializable()
class CreationResponse implements Schema {
	CreationResponse(this.nodeId, this.layerSettings, this.nodeConnectionLimits, );

	String nodeId;
	List<String> layerSettings;
	NodeConnectionLimits nodeConnectionLimits;

	factory CreationResponse.fromJson(Map<String, dynamic> json) => _$CreationResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$CreationResponseToJson(this);
}
