import 'package:json_annotation/json_annotation.dart';

part 'success_fail_response.g.dart';

@JsonSerializable()
class SuccessFailResponse {
	SuccessFailResponse(this.error, );

	String? error;

	factory SuccessFailResponse.fromJson(Map<String, dynamic> json) => _$SuccessFailResponseFromJson(json);

	Map<String, dynamic> toJson() => _$SuccessFailResponseToJson(this);
}
