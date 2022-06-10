import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'success_fail_response.g.dart';

@JsonSerializable()
class SuccessFailResponse extends RequestResponseSchema {
	SuccessFailResponse(this.error, );

	String? error;

	factory SuccessFailResponse.fromJson(Map<String, dynamic> json) => _$SuccessFailResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$SuccessFailResponseToJson(this);
}
