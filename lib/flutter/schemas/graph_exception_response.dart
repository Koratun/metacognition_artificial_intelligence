import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'graph_exception_response.g.dart';

@JsonSerializable()
class GraphExceptionResponse implements Schema {
	GraphExceptionResponse(this.error, );

	String error;

	factory GraphExceptionResponse.fromJson(Map<String, dynamic> json) => _$GraphExceptionResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$GraphExceptionResponseToJson(this);
}
