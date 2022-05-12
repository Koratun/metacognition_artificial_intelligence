import fileinput
from sys import stderr
import traceback
from humps import camelize
from pydantic import ValidationError
from python.directed_acyclic_graph import CompileErrorReason, DagException, DirectedAcyclicGraph, CompileException
from python.schemas import ResponseType, Command, CreateLayer, UpdateLayer, DeleteNode, Connection, layer_packages, layer_classes


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

    for line in fileinput.input():
        inp = line.rstrip()
        if 'Exit' == inp:
            break
        error = False
        try:
            command = inp[:inp.find('{')]
            payload = inp[inp.find('{'):]
            response = process(command, payload)
        except Exception as e:
            response = f"Fatal exception occurred: {str(e)}\n"+traceback.format_exc()
            error = True
        write_back(response, error=error)


def format_response(response_type: ResponseType, **kwargs):
    return response_type.camel() + response_type.get_model().parse_obj(camelize(kwargs)).json(by_alias=True)


def process(command: str, payload: str):
    try:
        if command == Command.CREATE.value:
            request = CreateLayer.parse_raw(payload)
            layer = layer_classes.get(request.layer)
            node = dag.add_node(layer())

            return format_response(
                ResponseType.CREATION,
                node_id=node.id,
                layer_settings=layer.get_settings_data_fields(),
                node_connection_limits=dict(
                    min_upstream=layer.min_upstream_nodes,
                    max_upstream=layer.max_upstream_nodes,
                    min_downstream=layer.min_downstream_nodes,
                    max_downstream=layer.max_downstream_nodes,
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
        elif command == Command.STARTUP.value:
            return format_response(ResponseType.STARTUP, category_list=layer_packages)
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
