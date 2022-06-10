import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';
import 'compile_error_reason_enum.dart';

part 'compile_error_response.g.dart';

@JsonSerializable()
class CompileErrorResponse extends RequestResponseSchema {
	CompileErrorResponse(this.nodeId, this.reason, this.errors, );

	String nodeId;
	CompileErrorReason reason;
	String errors;

	factory CompileErrorResponse.fromJson(Map<String, dynamic> json) => _$CompileErrorResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$CompileErrorResponseToJson(this);
}
