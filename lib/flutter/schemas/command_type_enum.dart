import 'package:flutter/foundation.dart';

enum CommandType {
	create,
	update,
	delete,
	connect,
	disconnect,
	compile,
}

extension CommandTypeExtension on CommandType {
	String get name => describeEnum(this);
}
