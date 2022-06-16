import 'package:flutter/foundation.dart';

enum CompileErrorReason {
	upstreamNodeCount,
	settingsValidation,
	inputMissing,
	disjointedGraph,
}

extension CompileErrorReasonExtension on CompileErrorReason {
	String get name => describeEnum(this);
}
