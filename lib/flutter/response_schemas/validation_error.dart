import 'package:json_annotation/json_annotation.dart';

part 'validation_error.g.dart';

@JsonSerializable()
class ValidationError {
	ValidationError(this.loc, this.msg, this.type, );

	List<String> loc;
	String msg;
	String type;

	factory ValidationError.fromJson(Map<String, dynamic> json) => _$ValidationErrorFromJson(json);

	Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);
}
