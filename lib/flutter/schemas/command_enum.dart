import 'package:flutter/foundation.dart';

enum Command {
	startup,
	create,
	update,
	delete,
	connect,
	disconnect,
	compile,
}

extension CommandExtension on Command {
	String get name => describeEnum(this);
}
