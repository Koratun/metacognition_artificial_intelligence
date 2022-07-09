import fileinput
from sys import stderr
import traceback
from humps import camelize
from pydantic import ValidationError
from python.layers import layer_packages, layer_classes
from python.directed_acyclic_graph import CompileErrorReason, DagException, DirectedAcyclicGraph, CompileException
from python.schemas import (
    RequestResponseModel,
    SchemaEnum,
    ResponseType,
    EventType,
    CommandType,
    CreateLayer,
    UpdateLayer,
    DeleteNode,
    Connection,
)


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
    write_back(format_response(EventType.INITIALIZE_LAYERS, category_list=layer_packages))

    for line in fileinput.input():
        inp: str = line.rstrip()
        if "Exit" == inp:
            break
        error = False
        try:
            if "{" not in inp or "}" not in inp:
                raise ValueError(
                    f'Improperly formatted request: "{inp}". '
                    + 'Expected string followed by json format. e.g. startup{} or create{"layer": "Input"}'
                )
            command = inp[: inp.find("{")]
            payload = inp[inp.find("{") :]
            response = process(command, payload)
        except Exception as e:
            response = f"Fatal exception occurred: {str(e)}\n" + traceback.format_exc()
            error = True
        write_back(response, error=error)


def format_response(out_type: SchemaEnum, **kwargs):
    return out_type.camel() + out_type.get_model().parse_obj(camelize(kwargs)).json(by_alias=True)


def process(command: str, payload: str):
    request_id = None
    try:
        if command == CommandType.CREATE.value:
            request = CreateLayer.parse_raw(payload)
            request_id = request.request_id
            layer = layer_classes.get(request.layer)
            node = dag.add_node(layer())

            return format_response(
                ResponseType.CREATION,
                request_id=request_id,
                node_id=node.id,
                layer_settings=layer.get_settings_data_fields(),
                node_connection_limits=dict(
                    min_upstream=layer.min_upstream_nodes,
                    max_upstream=layer.max_upstream_nodes,
                    min_downstream=layer.min_downstream_nodes,
                    max_downstream=layer.max_downstream_nodes,
                ),
            )
        elif command == CommandType.UPDATE.value:
            request = UpdateLayer.parse_raw(payload)
            request_id = request.request_id
            error = dag.get_node(request.id).layer.update_settings(request.settings)

            return format_response(ResponseType.SUCCESS_FAIL, request_id=request_id, error=error)
        elif command == CommandType.DELETE.value:
            request = DeleteNode.parse_raw(payload)
            request_id = request.request_id
            dag.remove_node(request.node_id)

            return format_response(ResponseType.SUCCESS_FAIL, request_id=request_id)
        elif command == CommandType.CONNECT.value or command == CommandType.DISCONNECT.value:
            request = Connection.parse_raw(payload)
            request_id = request.request_id
            if "d" in command:
                dag.disconnect_nodes(request.source_id, request.dest_id)
            else:
                dag.connect_nodes(request.source_id, request.dest_id)
            return format_response(ResponseType.SUCCESS_FAIL, request_id=request_id)
        elif command == CommandType.COMPILE.value:
            request = RequestResponseModel.parse_raw(payload)
            request_id = request.request_id
            return format_response(ResponseType.COMPILE_SUCCESS, request_id=request_id, py_file=dag.construct_keras())
    except DagException as e:
        return format_response(ResponseType.GRAPH_EXCEPTION, request_id=request_id, error=str(e))
    except CompileException as e:
        if e.error_data["reason"] == CompileErrorReason.DISJOINTED_GRAPH:
            return format_response(ResponseType.COMPILE_ERROR_DISJOINTED, request_id=request_id, **e.error_data)
        elif e.error_data["reason"] == CompileErrorReason.SETTINGS_VALIDATION:
            return format_response(
                ResponseType.COMPILE_ERROR_SETTINGS_VALIDATION, request_id=request_id, **e.error_data
            )
        else:
            return format_response(ResponseType.COMPILE_ERROR, request_id=request_id, **e.error_data)


if __name__ == "__main__":
    main()
