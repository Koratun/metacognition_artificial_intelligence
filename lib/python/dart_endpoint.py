from enum import Enum
import fileinput
import json
from sys import stderr
import traceback
from typing import Any, Type
from uuid import UUID
from pydantic import BaseModel, ValidationError, validator
from lib.python.directed_acyclic_graph import LayerSettings, LayerSyntaxException
from python.directed_acyclic_graph import DagException, DirectedAcyclicGraph, Layer

# When a new layer is created, add it to the list!
from python.layers import (
    input,
    dense, 
    output
)

layer_classes: dict[str, Type[Layer]] = {}
# Loop backwards through globals() until we hit 'Layer' 
# or whatever the first non-layer-subclass is

# We must wrap the globals call in a new dict because the very act
# of creating this loop will alter the global variables and 
# loops are not be able to iterate over changed iterators
for glob_mod_name, glob_mod in reversed(dict(globals()).items()):
    breakflag = False
    if glob_mod_name == 'input':
        breakflag = True
    if isinstance(glob_mod, type(input)):
        # This is a module!
        # Iterate through the module to find an attribute of type Layer
        for attr_name, attr in reversed(glob_mod.__dict__.items()):
            if isinstance(attr, type(Layer)):
                layer_classes[attr_name] = attr
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
    write_back("Py Starting")

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

    write_back("Ended")


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
    properties: dict[str, Any]
    required: list[str]


class UpdateLayer(CreateLayer):
    id: UUID
    settings: dict[str, str]

    @validator('settings', pre=True)
    def setting_fields_match(cls, v: dict, values: dict, **kwargs):
        layer: Type[Layer] = values['layer']
        setting_schema = MetaSchema.parse_obj(layer.settings_validator.schema())
        all_fields = sorted(list(setting_schema.properties.keys()))
        given_settings_fields = sorted(v.keys())
        if all_fields == given_settings_fields:
            return v
        raise ValueError("Fields do not match the given layer settings!")


class DeleteNode(BaseModel):
    id: UUID


class Connection(BaseModel):
    source_id: UUID
    dest_id: UUID


def format_response(errors=None, **kwargs):
    return json.dumps(dict(errors=errors, **kwargs))


def process(command: str, payload: str):
    try:
        if command == Command.CREATE.value:
            request = CreateLayer.parse_raw(payload)
            dag.add_node(request.layer())

            return format_response(
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
            errors = dag.get_node(request.id).layer.update_settings(request.settings)
            
            return format_response(errors=errors)
        elif command == Command.DELETE.value:
            request = DeleteNode.parse_raw(payload)
            dag.remove_node(request.id)
            
            return format_response()
        elif command == Command.CONNECT.value or command == Command.DISCONNECT.value:
            request = Connection.parse_raw(payload)
            if 'd' in command:
                dag.disconnect_nodes(request.source_id, request.dest_id)
            else:
                dag.connect_nodes(request.source_id, request.dest_id)
            return format_response()
        elif command == Command.COMPILE.value:
            return format_response(py_file=dag.construct_keras())
    except ValidationError as e:
        return e.json()
    except DagException as e:
        return format_response(errors=str(e))
    except LayerSyntaxException as e:
        return format_response(**e.args[0])
    


if __name__ == '__main__':
    main()