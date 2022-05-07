import 'package:json_annotation/json_annotation.dart';

part 'graph_exception_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GraphExceptionResponse {
	GraphExceptionResponse(this.error, );

	String error;

	factory GraphExceptionResponse.fromJson(Map<String, dynamic> json) => _$GraphExceptionResponseFromJson(json);

	Map<String, dynamic> toJson() => _$GraphExceptionResponseToJson(this);
}
