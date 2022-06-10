import 'package:flutter/foundation.dart';

enum CompileErrorReason {
	upstreamNodeCount,
	downstreamNodeCount,
	settingsValidation,
	compilationValidation,
	inputMissing,
	disjointedGraph,
}

extension CompileErrorReasonExtension on CompileErrorReason {
	String get name => describeEnum(this);
}
