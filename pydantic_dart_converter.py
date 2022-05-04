from pydantic import BaseModel
from enum import Enum
from typing import Type
import lib.python.response_schemas as response_schemas
from lib.python.dart_endpoint import MetaSchema

# This script is used to convert the pydantic schemas and enums to Dart schemas and enums.


def main():
    for obj in response_schemas.__dict__.values():
        if issubclass(obj, BaseModel) and obj != BaseModel:
            make_dart_schema(obj)
        elif issubclass(obj, Enum) and obj != Enum:
            make_dart_enum(obj)


def pascal_to_snake(s: str):
    snake_string = ''
    for i, c in enumerate(s):
        if i == 0:
            snake_string += c.lower()
        elif c.isupper():
            snake_string += '_' + c.lower()
        else:
            snake_string += c
    return snake_string


def snake_to_camel(s: str):
    camel_string = ''
    for i, c in enumerate(s):
        if i == 0:
            camel_string += c
        elif c == '_':
            camel_string += s[i + 1].upper()
        elif camel_string[-1].isupper():
            continue
        else:
            camel_string += c
    return camel_string


def make_dart_enum(enum_cls: Type[Enum]):
    with open('lib/flutter/response_schemas/{}_enum.dart'.format(pascal_to_snake(enum_cls.__name__)), 'w') as f:
        f.write(f"enum {enum_cls.__name__} {{")
        for enum_value in enum_cls:
            f.write(f"\n  {snake_to_camel(enum_value.value)},")
        f.write("\n}")


python_dart_type_map = {
    'int': 'int',
    'float': 'double',
    'bool': 'bool',
    'str': 'String',
    'UUID': 'Uuid',
    'list': 'List<dynamic>',
    'dict': 'Map<String, dynamic>',
    'tuple': 'List<dynamic>',
}


# Write a dart class conforming with json_serializable code generation format in dart
def make_dart_schema(model_cls: Type[BaseModel]):
    model_schema = MetaSchema.parse_obj(model_cls.schema())

    with open('lib/flutter/response_schemas/{}.dart'.format(pascal_to_snake(model_cls.__name__)), 'w') as f:
        f.write("import 'package:json_annotation/json_annotation.dart';\n")
        f.write("\n")
        f.write(f"part '{pascal_to_snake(model_cls.__name__)}.g.dart';\n")
        f.write("\n")
        f.write("@JsonSerializable(fieldRename: FieldRename.snake)\n")
        f.write(f"class {model_cls.__name__} {{")

        for field in model_cls.__fields__:
            f.write(f"\n  {field.type.__name__} {field.name};")

