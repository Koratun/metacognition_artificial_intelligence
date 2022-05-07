import 'package:json_annotation/json_annotation.dart';

part 'compile_success_response.g.dart';

@JsonSerializable()
class CompileSuccessResponse {
	CompileSuccessResponse(this.pyFile, );

	String pyFile;

	factory CompileSuccessResponse.fromJson(Map<String, dynamic> json) => _$CompileSuccessResponseFromJson(json);

	Map<String, dynamic> toJson() => _$CompileSuccessResponseToJson(this);
}
