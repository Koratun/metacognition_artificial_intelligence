import 'package:flutter/foundation.dart';
import 'schema.dart';
import 'success_fail_response.dart';
import 'creation_response.dart';
import 'validation_response.dart';
import 'graph_exception_response.dart';
import 'compile_error_response.dart';
import 'compile_error_disjointed_response.dart';
import 'compile_error_settings_validation_response.dart';

enum ResponseType {
	successFail,
	creation,
	validation,
	graphException,
	compileError,
	compileErrorDisjointed,
	compileErrorSettingsValidation,
}

Map<ResponseType, RequestResponseSchema Function(Map<String, dynamic>)> _fromJsonMap = {
	ResponseType.successFail: SuccessFailResponse.fromJson,
	ResponseType.creation: CreationResponse.fromJson,
	ResponseType.validation: ValidationResponse.fromJson,
	ResponseType.graphException: GraphExceptionResponse.fromJson,
	ResponseType.compileError: CompileErrorResponse.fromJson,
	ResponseType.compileErrorDisjointed: CompileErrorDisjointedResponse.fromJson,
	ResponseType.compileErrorSettingsValidation: CompileErrorSettingsValidationResponse.fromJson,
};

extension ResponseTypeExtension on ResponseType {
	String get name => describeEnum(this);
	RequestResponseSchema Function(Map<String, dynamic>)? get schemaFromJson => _fromJsonMap[this];
}
