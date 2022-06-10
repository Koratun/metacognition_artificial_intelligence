import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'validation_error.g.dart';

@JsonSerializable()
class ValidationError extends Schema {
	ValidationError(this.loc, this.msg, this.type, );

	List<String> loc;
	String msg;
	String type;

	factory ValidationError.fromJson(Map<String, dynamic> json) => _$ValidationErrorFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);
}
