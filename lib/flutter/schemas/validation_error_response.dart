import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';
import 'validation_error.dart';

part 'validation_error_response.g.dart';

@JsonSerializable()
class ValidationErrorResponse extends RequestResponseSchema {
	ValidationErrorResponse(this.errors, );

	List<ValidationError> errors;

	factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) => _$ValidationErrorResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$ValidationErrorResponseToJson(this);
}
