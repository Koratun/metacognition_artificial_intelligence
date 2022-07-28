import 'package:flutter/foundation.dart';

enum Activation {
	relu,
	sigmoid,
	softmax,
	tanh,
	selu,
	elu,
}

extension ActivationExtension on Activation {
	String get name => describeEnum(this);
}
