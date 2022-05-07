import 'package:json_annotation/json_annotation.dart';

part 'delete_node.g.dart';

@JsonSerializable()
class DeleteNode {
	DeleteNode(this.id, );

	String id;

	factory DeleteNode.fromJson(Map<String, dynamic> json) => _$DeleteNodeFromJson(json);

	Map<String, dynamic> toJson() => _$DeleteNodeToJson(this);
}
