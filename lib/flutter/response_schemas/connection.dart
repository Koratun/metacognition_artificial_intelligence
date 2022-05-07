import 'package:json_annotation/json_annotation.dart';

part 'connection.g.dart';

@JsonSerializable()
class Connection {
	Connection(this.sourceId, this.destId, );

	String sourceId;
	String destId;

	factory Connection.fromJson(Map<String, dynamic> json) => _$ConnectionFromJson(json);

	Map<String, dynamic> toJson() => _$ConnectionToJson(this);
}
