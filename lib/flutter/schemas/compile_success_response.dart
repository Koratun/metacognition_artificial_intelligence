import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'compile_success_response.g.dart';

@JsonSerializable()
class CompileSuccessResponse extends RequestResponseSchema {
	CompileSuccessResponse(this.pyFile, );

	String pyFile;

	factory CompileSuccessResponse.fromJson(Map<String, dynamic> json) => _$CompileSuccessResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$CompileSuccessResponseToJson(this);
}
