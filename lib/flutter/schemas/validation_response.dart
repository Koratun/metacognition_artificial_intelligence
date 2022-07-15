import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';
import 'validation_error.dart';

part 'validation_response.g.dart';

@JsonSerializable()
class ValidationResponse extends RequestResponseSchema {
	ValidationResponse(this.errors, );

	List<ValidationError>? errors;

	factory ValidationResponse.fromJson(Map<String, dynamic> json) => _$ValidationResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$ValidationResponseToJson(this);
}
