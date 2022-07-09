from pydantic import BaseModel
from enum import Enum
from typing import Type
import python.schemas as schemas
import os
from tqdm import tqdm

# This script is used to convert the pydantic schemas and enums to Dart schemas and enums.


def main():
    # Nuke schemas folder
    for file in os.listdir("lib/flutter/schemas"):
        if file != "schema.dart":
            os.remove("lib/flutter/schemas/" + file)

    # Search through schemas file to generate enums and schemas for dart
    for obj in tqdm(schemas.__dict__.values(), desc="Generating schemas"):
        if isinstance(obj, type):
            if issubclass(obj, BaseModel) and obj not in (
                BaseModel,
                schemas.MetaSchema,
                schemas.CamelModel,
                schemas.RequestResponseModel,
            ):
                make_dart_schema(obj)
            elif issubclass(obj, Enum) and obj not in (Enum, schemas.SchemaEnum):
                make_dart_enum(obj)

    # Lower the chance of human error
    print("> flutter pub run build_runner build --delete-conflicting-outputs")
    os.system("flutter pub run build_runner build --delete-conflicting-outputs")


def pascal_to_snake(s: str):
    snake_string = ""
    for i, c in enumerate(s):
        if i == 0:
            snake_string += c.lower()
        elif c.isupper():
            snake_string += "_" + c.lower()
        else:
            snake_string += c
    return snake_string


def snake_to_camel(s: str):
    camel_string = ""
    for i, c in enumerate(s):
        if i == 0:
            camel_string += c
        elif c == "_":
            camel_string += s[i + 1].upper()
        elif s[i - 1] == "_":
            continue
        else:
            camel_string += c
    return camel_string


def make_dart_enum(enum_cls: Type[Enum]):
    is_outgoing = enum_cls in (schemas.EventType, schemas.ResponseType)
    with open("lib/flutter/schemas/{}_enum.dart".format(pascal_to_snake(enum_cls.__name__)), "w") as f:
        f.write("import 'package:flutter/foundation.dart';\n")
        if is_outgoing:
            f.write("import 'schema.dart';\n")
            # Cycle thru schemas to get their snake_case class names
            for model in enum_cls.model_rep.values():
                f.write(f"import '{pascal_to_snake(model.__name__)}.dart';\n")

        f.write("\n")
        f.write(f"enum {enum_cls.__name__} {{")
        for enum_value in enum_cls:
            f.write(f"\n\t{snake_to_camel(enum_value.value)},")
        f.write("\n}\n\n")

        if is_outgoing:
            schema_type_name = "RequestResponseSchema" if enum_cls is schemas.ResponseType else "Schema"
            f.write(f"Map<{enum_cls.__name__}, {schema_type_name} Function(Map<String, dynamic>)> _fromJsonMap = {{\n")
            # Cycle thru key/value pairs to make dart equivalent
            for e, m in enum_cls.model_rep.items():
                f.write(f"\t{enum_cls.__name__}.{snake_to_camel(e.value)}: {m.__name__}.fromJson,\n")
            f.write("};\n\n")

        f.write(f"extension {enum_cls.__name__}Extension on {enum_cls.__name__} {{\n")
        f.write("\tString get name => describeEnum(this);\n")

        if is_outgoing:
            f.write(f"\t{schema_type_name} Function(Map<String, dynamic>)? get schemaFromJson => _fromJsonMap[this];\n")

        f.write("}\n")


pydantic_dart_type_map = {
    "integer": "int",
    "number": "double",
    "string": "String",
    "boolean": "bool",
    "array": "List<dynamic>",
    "object": "Map<String, dynamic>",
}


# Write a dart class conforming with json_serializable code generation format in dart
def make_dart_schema(model_cls: Type[BaseModel]):
    model_schema = schemas.MetaSchema.parse_obj(model_cls.schema())
    # Gather all properties of the schema and their types
    properties: dict[str, str] = {}
    # For enums and pydantic submodels, we need to import those as well from the dart files
    additional_imports: list[str] = []
    for prop_name, prop_schema in model_schema.properties.items():
        if "$ref" in prop_schema:
            # This is a reference to another schema, so the foreign schema is the type
            properties[prop_name] = prop_schema["$ref"].split("/")[-1]
            # Add the foreign schema to the imports
            snake_case_name = pascal_to_snake(properties[prop_name])
            if "enum" in model_schema.definitions[properties[prop_name]]:
                snake_case_name += "_enum"
            additional_imports.append(snake_case_name)
        else:
            properties[prop_name] = pydantic_dart_type_map.get(prop_schema["type"])
            while "dynamic" in properties[prop_name]:
                # To enter this loop the prop_schema type must be of type array or object
                if prop_schema["type"] == "array":
                    prop_getter = "items"
                elif prop_schema["type"] == "object":
                    prop_getter = "additionalProperties"
                if "$ref" in prop_schema[prop_getter]:
                    sub_prop_name = prop_schema[prop_getter]["$ref"].split("/")[-1]
                    properties[prop_name] = properties[prop_name].replace("dynamic", sub_prop_name)
                    # Add the foreign schema to the imports
                    snake_case_name = pascal_to_snake(sub_prop_name)
                    if "enum" in model_schema.definitions[sub_prop_name]:
                        snake_case_name += "_enum"
                    additional_imports.append(snake_case_name)
                else:
                    properties[prop_name] = properties[prop_name].replace(
                        "dynamic", pydantic_dart_type_map.get(prop_schema[prop_getter]["type"])
                    )
                    prop_schema = prop_schema[prop_getter]

    required_camels = model_schema.required if model_schema.required else []

    with open("lib/flutter/schemas/{}.dart".format(pascal_to_snake(model_cls.__name__)), "w") as f:
        f.write("import 'package:json_annotation/json_annotation.dart';\n")
        f.write("import 'schema.dart';\n")
        for import_name in additional_imports:
            f.write(f"import '{import_name}.dart';\n")
        f.write("\n")
        f.write(f"part '{pascal_to_snake(model_cls.__name__)}.g.dart';\n")
        f.write("\n")

        # could use this if pydantic aliasing isn't sufficient -> fieldRename: FieldRename.snake
        f.write("@JsonSerializable()\n")
        schema_type_name = "RequestResponseSchema" if "requestId" in properties else "Schema"
        f.write(f"class {model_cls.__name__} extends {schema_type_name} {{\n")
        f.write(f"\t{model_cls.__name__}(")
        for prop_name in properties.keys():
            if prop_name != "requestId":
                f.write(f"this.{prop_name}, ")
        f.write(");\n")
        f.write("\n")

        for prop_name, prop_type in properties.items():
            if prop_name != "requestId":
                f.write(f"\t{prop_type}{'?' if prop_name not in required_camels else ''} {prop_name};\n")
        f.write("\n")

        f.write(
            f"\tfactory {model_cls.__name__}.fromJson(Map<String, dynamic> json) => _${model_cls.__name__}FromJson(json);\n"
        )
        f.write("\n")
        f.write("\t@override\n")
        f.write(f"\tMap<String, dynamic> toJson() => _${model_cls.__name__}ToJson(this);\n")
        f.write("}\n")


if __name__ == "__main__":
    main()
