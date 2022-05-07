import 'package:json_annotation/json_annotation.dart';

part 'startup_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StartupResponse {
	StartupResponse(this.categoryList, );

	Map<String, List<String>> categoryList;

	factory StartupResponse.fromJson(Map<String, dynamic> json) => _$StartupResponseFromJson(json);

	Map<String, dynamic> toJson() => _$StartupResponseToJson(this);
}
