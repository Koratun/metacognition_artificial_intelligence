import 'package:flutter/foundation.dart';
import 'schema.dart';
import 'initialize_layers_event.dart';
import 'init_fit_event.dart';

enum EventType {
	initializeLayers,
	initFit,
}

Map<EventType, Schema Function(Map<String, dynamic>)> _fromJsonMap = {
	EventType.initializeLayers: InitializeLayersEvent.fromJson,
	EventType.initFit: InitFitEvent.fromJson,
};

extension EventTypeExtension on EventType {
	String get name => describeEnum(this);
	Schema Function(Map<String, dynamic>)? get schemaFromJson => _fromJsonMap[this];
}
