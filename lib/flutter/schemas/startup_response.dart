import 'package:json_annotation/json_annotation.dart';
import 'schema.dart';

part 'startup_response.g.dart';

@JsonSerializable()
class StartupResponse implements Schema {
	StartupResponse(this.categoryList, );

	Map<String, List<String>> categoryList;

	factory StartupResponse.fromJson(Map<String, dynamic> json) => _$StartupResponseFromJson(json);

	@override
	Map<String, dynamic> toJson() => _$StartupResponseToJson(this);
}
