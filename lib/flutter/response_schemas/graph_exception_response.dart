import 'package:json_annotation/json_annotation.dart';

part 'graph_exception_response.g.dart';

@JsonSerializable()
class GraphExceptionResponse {
	GraphExceptionResponse(this.error, );

	String error;

	factory GraphExceptionResponse.fromJson(Map<String, dynamic> json) => _$GraphExceptionResponseFromJson(json);

	Map<String, dynamic> toJson() => _$GraphExceptionResponseToJson(this);
}
