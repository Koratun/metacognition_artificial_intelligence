from enum import Enum
import fileinput
from sys import stderr
import traceback
from typing import Any, Optional, Type
from uuid import UUID
from pydantic import BaseModel, ValidationError, validator
from python.directed_acyclic_graph import CompileErrorReason, DagException, DirectedAcyclicGraph, Layer, CompileException
from python.response_schemas import ResponseType
from pathlib import Path

# When a new layer is created, add it to the list!
from python.layers import (
    input,
    dense, 
    output
)

layer_classes: dict[str, Type[Layer]] = {}
# Loop backwards through globals() until we hit 'Layer' 
# or whatever the first non-layer-subclass is

layer_packages: dict[str, list[str]] = {}

# We must wrap the globals call in a new dict because the very act
# of creating this loop will alter the global variables and 
# loops are not be able to iterate over changed iterators
for glob_mod_name, glob_mod in reversed(dict(globals()).items()):
    breakflag = False
    if glob_mod_name == 'input':
        breakflag = True
    if isinstance(glob_mod, type(input)):
        mod_parent = Path(glob_mod.__file__).parent.name
        if mod_parent == 'layers':
            mod_parent = 'core'
        # This is a module!
        # Iterate through the module to find an attribute of type Layer
        for attr_name, attr in reversed(glob_mod.__dict__.items()):
            if isinstance(attr, type(Layer)):
                layer_classes[attr_name] = attr
                if package_list := layer_packages.get(mod_parent):
                    package_list.append(attr_name)
                else:
                    layer_packages[mod_parent] = [attr_name]
                break

    if breakflag:
        break


dag = DirectedAcyclicGraph()


def write_back(s: str, error=False):
    if error:
        print(s, file=stderr, flush=True)
    else:
        print(s, flush=True)


def main():
    """
    Endpoint must be called with the following format:
    create{
        "layer": "Input" PascalCase
    }
    update{
        id: UUID
        layer: Layer
        payload: dict
    }

    delete{
        id: UUID
    }

    compile{}
    """
    write_back(format_response(ResponseType.STARTUP, category_list=layer_packages))

    for line in fileinput.input():
        inp = line.rstrip()
        if 'Exit' == inp:
            break
        error = False
        try:
            command = inp[:inp.find('{')]
            payload = inp[inp.find('{'):]
            response = process(command, payload)
        except Exception:
            response = "Fatal exception occurred:\n"+traceback.format_exc()
            error = True
        write_back(response, error=error)


class Command(Enum):
    CREATE = 'create'
    UPDATE = 'update'
    DELETE = 'delete'
    CONNECT = 'connect'
    DISCONNECT = 'disconnect'
    COMPILE = 'compile'


class CreateLayer(BaseModel):
    layer: Type[Layer]

    @validator('layer', pre=True)
    def is_valid_layer(cls, v):
        if l := layer_classes.get(v):
            return l
        raise ValueError("Layer type not found")


class MetaSchema(BaseModel):
    title: str
    type: str
    properties: dict[str, dict[str, Any]]
    required: Optional[list[str]]
    definitions: Optional[dict[str, dict[str, Any]]]


class UpdateLayer(CreateLayer):
    id: UUID
    settings: dict[str, str]

    @validator('settings', pre=True)
    def setting_fields_match(cls, v: dict, values: dict, **kwargs):
        layer: Type[Layer] = values.get('layer')
        if not layer:
            raise ValueError("Layer not provided")
        setting_schema = MetaSchema.parse_obj(layer.settings_validator.schema())
        all_fields = list(setting_schema.properties.keys())
        for given_field in v.keys():
            if given_field not in all_fields:
                raise ValueError(f"{given_field} is not a valid setting field for: {layer.__name__}")
        return v


class DeleteNode(BaseModel):
    id: UUID


class Connection(BaseModel):
    source_id: UUID
    dest_id: UUID


def format_response(response_type: ResponseType, **kwargs):
    return response_type.camel() + response_type.get_model()(**kwargs).json()


def process(command: str, payload: str):
    try:
        if command == Command.CREATE.value:
            request = CreateLayer.parse_raw(payload)
            node = dag.add_node(request.layer())

            return format_response(
                ResponseType.CREATION,
                node_id=node.id,
                layer_settings=request.layer.get_settings_data_fields(),
                node_connection_limits=dict(
                    min_upstream=request.layer.min_upstream_nodes,
                    max_upstream=request.layer.max_upstream_nodes,
                    min_downstream=request.layer.min_downstream_nodes,
                    max_downstream=request.layer.max_downstream_nodes,
                )
            )
        elif command == Command.UPDATE.value:
            request = UpdateLayer.parse_raw(payload)
            error = dag.get_node(request.id).layer.update_settings(request.settings)
            
            return format_response(ResponseType.SUCCESS_FAIL, error=error)
        elif command == Command.DELETE.value:
            request = DeleteNode.parse_raw(payload)
            dag.remove_node(request.id)
            
            return format_response(ResponseType.SUCCESS_FAIL)
        elif command == Command.CONNECT.value or command == Command.DISCONNECT.value:
            request = Connection.parse_raw(payload)
            if 'd' in command:
                dag.disconnect_nodes(request.source_id, request.dest_id)
            else:
                dag.connect_nodes(request.source_id, request.dest_id)
            return format_response(ResponseType.SUCCESS_FAIL)
        elif command == Command.COMPILE.value:
            return format_response(ResponseType.COMPILE_SUCCESS, py_file=dag.construct_keras())
    except ValidationError as e:
        return format_response(ResponseType.VALIDATION_ERROR, __root__=e.errors())
    except DagException as e:
        return format_response(ResponseType.GRAPH_EXCEPTION, error=str(e))
    except CompileException as e:
        if e.error_data['reason'] == CompileErrorReason.DISJOINTED_GRAPH.camel():
            return format_response(ResponseType.COMPILE_ERROR_DISJOINTED, **e.error_data)
        elif e.error_data['reason'] == CompileErrorReason.SETTINGS_VALIDATION.camel():
            return format_response(ResponseType.COMPILE_ERROR_SETTINGS_VALIDATION, **e.error_data)
        else:
            return format_response(ResponseType.COMPILE_ERROR, **e.error_data)
    


if __name__ == '__main__':
    main()