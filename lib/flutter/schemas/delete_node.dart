import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'delete_node.g.dart';

@JsonSerializable()
class DeleteNode extends RequestResponseSchema {
	DeleteNode(this.nodeId, );

	String nodeId;

	factory DeleteNode.fromJson(Map<String, dynamic> json) => _$DeleteNodeFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$DeleteNodeToJson(this);
}
