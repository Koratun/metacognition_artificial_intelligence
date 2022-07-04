import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'node_connection_limits.g.dart';

@JsonSerializable()
class NodeConnectionLimits extends Schema {
	NodeConnectionLimits(this.minUpstream, this.maxUpstream, this.minDownstream, this.maxDownstream, );

	int minUpstream;
	String maxUpstream;
	int minDownstream;
	String maxDownstream;

	factory NodeConnectionLimits.fromJson(Map<String, dynamic> json) => _$NodeConnectionLimitsFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$NodeConnectionLimitsToJson(this);
}
