import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';
import 'compile_error_reason_enum.dart';

part 'compile_error_disjointed_response.g.dart';

@JsonSerializable()
class CompileErrorDisjointedResponse implements Schema {
	CompileErrorDisjointedResponse(this.nodeIds, this.reason, this.errors, );

	List<String> nodeIds;
	CompileErrorReason reason;
	String errors;

	factory CompileErrorDisjointedResponse.fromJson(Map<String, dynamic> json) => _$CompileErrorDisjointedResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$CompileErrorDisjointedResponseToJson(this);
}
