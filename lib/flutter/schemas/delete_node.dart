import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'delete_node.g.dart';

@JsonSerializable()
class DeleteNode implements Schema {
	DeleteNode(this.id, );

	String id;

	factory DeleteNode.fromJson(Map<String, dynamic> json) => _$DeleteNodeFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$DeleteNodeToJson(this);
}
