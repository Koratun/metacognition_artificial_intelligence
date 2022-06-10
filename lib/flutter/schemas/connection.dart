import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'connection.g.dart';

@JsonSerializable()
class Connection extends RequestResponseSchema {
	Connection(this.sourceId, this.destId, );

	String sourceId;
	String destId;

	factory Connection.fromJson(Map<String, dynamic> json) => _$ConnectionFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$ConnectionToJson(this);
}
