import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';
import 'validation_error.dart';
import 'compile_error_reason_enum.dart';

part 'compile_error_settings_validation_response.g.dart';

@JsonSerializable()
class CompileErrorSettingsValidationResponse extends RequestResponseSchema {
	CompileErrorSettingsValidationResponse(this.errors, this.nodeId, this.reason, );

	List<ValidationError> errors;
	String nodeId;
	CompileErrorReason reason;

	factory CompileErrorSettingsValidationResponse.fromJson(Map<String, dynamic> json) => _$CompileErrorSettingsValidationResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$CompileErrorSettingsValidationResponseToJson(this);
}
