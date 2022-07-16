import 'package:flutter/foundation.dart';

enum Dtype {
	bfloat16,
	bool,
	complex128,
	complex64,
	double,
	float16,
	float32,
	float64,
	half,
	int16,
	int32,
	int64,
	int8,
	qint16,
	qint32,
	qint8,
	quint16,
	quint8,
	resource,
	string,
	uint16,
	uint32,
	uint64,
	uint8,
	variant,
}

extension DtypeExtension on Dtype {
	String get name => describeEnum(this);
}
