import 'package:uuid/uuid.dart';

class Schema {
  const Schema();

  Map<String, dynamic> toJson() => <String, dynamic>{};
}

class RequestResponseSchema extends Schema {
  final uuid = const Uuid();

  late String requestId = uuid.v4();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{"requestId": requestId};
}
