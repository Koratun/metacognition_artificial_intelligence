import 'package:json_annotation/json_annotation.dart';
import 'validation_error.dart';

part 'validation_error_response.g.dart';

@JsonSerializable()
class ValidationErrorResponse {
	ValidationErrorResponse(this.errors, );

	List<ValidationError> errors;

	factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) => _$ValidationErrorResponseFromJson(json);

	Map<String, dynamic> toJson() => _$ValidationErrorResponseToJson(this);
}
