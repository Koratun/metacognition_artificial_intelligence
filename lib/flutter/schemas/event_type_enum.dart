import 'package:flutter/foundation.dart';
import 'schema.dart';
import 'initialize_layers_event.dart';

enum EventType {
	initializeLayers,
}

Map<EventType, Schema Function(Map<String, dynamic>)> _fromJsonMap = {
	EventType.initializeLayers: InitializeLayersEvent.fromJson,
};

extension EventTypeExtension on EventType {
	String get name => describeEnum(this);
	Schema Function(Map<String, dynamic>)? get schemaFromJson => _fromJsonMap[this];
}
