import 'package:flutter/foundation.dart';

enum ResponseType {
	startup,
	successFail,
	creation,
	validationError,
	graphException,
	compileError,
	compileErrorDisjointed,
	compileErrorSettingsValidation,
	compileSuccess,
}

extension ResponseTypeExtension on ResponseType {
	String get name => describeEnum(this);
}
