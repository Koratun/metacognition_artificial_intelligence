from enum import Enum
import fileinput
from typing import Any, Optional, Type, Union
from uuid import UUID
from wsgiref.validate import validator
from pydantic import BaseModel, ValidationError
from python.directed_acyclic_graph import DirectedAcyclicGraph, Layer

dag = DirectedAcyclicGraph()


def write_back(s: str):
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
    """
    write_back("Py Starting")

    for line in fileinput.input():
        inp = line.rstrip()
        if 'Exit' == inp:
            break
        command = inp[:inp.find('{')]
        payload = inp[inp.find('{'):]
        process(command, payload)

    write_back("Ended")


class Command(Enum):
    CREATE = 'create'
    UPDATE = 'update'
    DELETE = 'delete'
    CONNECT = 'connect'
    DISCONNECT = 'disconnect'


class CreateLayer(BaseModel):
    layer: Type[Layer]

    @validator('layer', pre=True)
    def is_valid_layer(cls, v):
        if l := globals().get(v):
            return l
        raise ValueError("Layer type not found")


class MetaSchema(BaseModel):
    title: str
    type: str
    properties: dict[str, Any]
    required: list[str]


class UpdateLayer(CreateLayer):
    id: UUID
    payload: dict[str, str]

    @validator('payload', pre=True)
    def setting_fields_match(cls, v: dict, values: dict, **kwargs):
        layer: Type[Layer] = values['layer']
        setting_schema = MetaSchema.parse_obj(layer.settings_validator.schema())
        all_fields = sorted(list(setting_schema.properties.keys()))
        payload_fields = sorted(v.keys())
        if all_fields == payload_fields:
            return v
        raise ValueError("Fields do not match the given layer settings!")


class DeleteNode(BaseModel):
    id: UUID


class Connection(BaseModel):
    source_id: UUID
    dest_id: UUID



def process(command: str, payload: str):
    if command == Command.CREATE.value:
        pass
    


if __name__ == '__main__':
    main()