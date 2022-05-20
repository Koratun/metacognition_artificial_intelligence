from uuid import UUID, uuid4
from enum import Enum
from typing import Type
from humps import camelize
from pydantic import BaseModel, ValidationError, validator
from pydantic.fields import ModelField


class CompileException(Exception):
    def __init__(self, error_data: dict, *args: object) -> None:
        self.error_data = error_data
        super().__init__(error_data, *args)


class CompileErrorReason(Enum):
    """
    The reason why a layer failed to construct.
    """
    UPSTREAM_NODE_COUNT = 'upstream_node_count'
    SETTINGS_VALIDATION = 'settings_validation'
    INPUT_MISSING = 'input_missing'
    DISJOINTED_GRAPH = 'disjointed_graph'

    def camel(self) -> str:
        return camelize(self.value)


class LayerSettings(BaseModel):
    @validator('*', pre=True)
    def string_validator(cls, v, field: ModelField):
        if v == '':
            return None
        if field.outer_type_ is str or issubclass(field.outer_type_, Enum):
            return v
        try:
            # The empty dictionary is to prevent security threats 
            # in the form of injection attacks
            return eval(v, {})
        except Exception:
            raise ValueError("Invalid formatting")


class Layer:
    settings_validator: Type[LayerSettings] = None
    type = 'base_layer'
    keras_module_location = 'layers'
    min_upstream_nodes = 1
    max_upstream_nodes = 1
    min_downstream_nodes = 1
    max_downstream_nodes = 1

    def __init__(self):
        self.layer_id = uuid4()
        self.name = self.type
        self.constructed = False
        self.settings_data = {k: '' for k in self.get_settings_data_fields()}

    @classmethod
    def get_settings_data_fields(cls):
        response: dict = cls.settings_validator.schema()['properties']
        return list(response.keys())

    def update_settings(self, settings: dict):
        """This method assumes that the settings match this layer's schema"""
        self.settings_data.update(settings)
        return self.validate_settings()

    def validate_settings(self):
        try:
            self.settings_validator(**self.settings_data)
        except ValidationError as e:
            return e.errors()

    def reset_construct(self):
        self.constructed = False

    def check_number_upstream_nodes(self, n: int) -> bool:
        return self.min_upstream_nodes <= n and n <= self.max_upstream_nodes 

    def check_number_downstream_nodes(self, n: int) -> bool:
        return self.min_downstream_nodes <= n and n <= self.max_downstream_nodes 

    def construct_settings(self):
        set_settings: dict = self.settings_validator(**self.settings_data).dict(exclude_defaults=True)
        return ', '.join(f'{k}={v}' for k, v in set_settings.items())

    def generate_code_line(self, node_being_built: 'DagNode') -> str:
        """
        Generate the code line for this layer.
        It must validate the syntax first before continuing.
        It must set the `constructed` attribute to True.
        """
        try:
            if self.constructed:
                line = self.name + ' = ' + self.name
            else:
                line = self.name + f' = {self.keras_module_location}.' + self.__name__ + '(' + self.construct_settings() + ')'
                self.constructed = True
            if len(node_being_built.upstream_nodes) != 1:
                raise CompileException({
                    'node_id': str(node_being_built.id), 
                    'reason': CompileErrorReason.UPSTREAM_NODE_COUNT.camel(), 
                    'errors': 'Layer must have exactly one upstream node'
                })
            line += '(' + node_being_built.upstream_nodes[0].layer.name + ')'
            return line
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.SETTINGS_VALIDATION.camel(), 
                'errors': e.errors()
            })


class DagException(Exception):
    def __init__(self, *args: object):
        super().__init__(*args)


class DagNode:
    def __init__(self, layer: Layer):
        self.id = uuid4()
        self.layer = layer
        self.upstream_nodes: list[DagNode] = []
        self.downstream_nodes: list[DagNode] = []
        self.seen = False

    def code_gen(self) -> str:
        return self.layer.generate_code_line(self)

    def connect_to(self, node: 'DagNode'):
        self.add_downstream_node(node)
        node.add_upstream_node(self)

    def disconnect_from(self, node: 'DagNode'):
        self.remove_downstream_node(node)
        node.remove_upstream_node(self)

    def check_node_connection_limits(self):
        return (
            self.layer.check_number_upstream_nodes(len(self.upstream_nodes)) and 
            self.layer.check_number_downstream_nodes(len(self.downstream_nodes))
        )

    def add_upstream_node(self, node: 'DagNode'):
        self.upstream_nodes.append(node)

    def add_downstream_node(self, node: 'DagNode'):
        self.downstream_nodes.append(node)

    def remove_upstream_node(self, node: 'DagNode'):
        self.upstream_nodes.remove(node)

    def remove_downstream_node(self, node: 'DagNode'):
        self.downstream_nodes.remove(node)


class DirectedAcyclicGraph:
    def __init__(self):
        self.nodes: list[DagNode] = []
        self.edges: list[tuple[DagNode, DagNode]] = []


    def _unsee(self, construct=False):
        for n in self.nodes:
            n.seen = False
            if construct:
                n.layer.reset_construct()


    def get_head_nodes(self) -> list[DagNode]:
        for e in self.edges:
            e[1].seen = True
        head_nodes = [n for n in self.nodes if not n.seen]
        self._unsee()
        return head_nodes


    def get_node(self, node_id: UUID) -> DagNode:
        for n in self.nodes:
            if n.id == node_id:
                return n
        raise DagException("Node not found")


    def check_cyclic(self) -> bool:
        if len(self.edges) < 1:
            return True
        if heads := self.get_head_nodes():
            for head in heads:
                head.seen = True
                if not self._check_cyclic(head):
                    self._unsee()
                    return False
        else:
            return False
        cyclic = len([n for n in self.nodes if not n.seen]) == 0
        self._unsee()
        return cyclic

    
    def _check_cyclic(self, node: DagNode) -> bool:
        for n in node.downstream_nodes:
            if n.seen:
                return False
            n.seen = True
            if not self._check_cyclic(n):
                return False
        return True


    def connect_nodes(self, source_id: UUID, dest_id: UUID):
        source_node, dest_node = self.get_node(source_id), self.get_node(dest_id)
        if (source_node, dest_node) in self.edges:
            raise DagException("Connection already exists")
        else:
            self.edges.append((source_node, dest_node))
            source_node.connect_to(dest_node)
            if not source_node.check_node_connection_limits():
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Source node has too many connections")
            elif not dest_node.check_node_connection_limits():
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Destination node has too many connections")
            elif not self.check_cyclic(): 
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Circular graphs not allowed")


    def disconnect_nodes(self, source_id: UUID, dest_id: UUID):
        source_node, dest_node = self.get_node(source_id), self.get_node(dest_id)
        if (source_node, dest_node) in self.edges:
            self.edges.remove((source_node, dest_node))
            source_node.disconnect_from(dest_node)
        else:
            raise DagException("Connection not found")


    def add_node(self, layer: Layer) -> DagNode:
        node = DagNode(layer)
        self.nodes.append(node)
        return node


    def remove_node(self, node_id: UUID):
        node = self.get_node(node_id)
        self.nodes.remove(node)
        for e in list(self.edges):
            if node in e:
                self.edges.remove(e)


    def _check_graph_whole(self):
        start_node = self.edges[0][0]
        start_node.seen = True
        for n in start_node.upstream_nodes:
            n.seen = True
            self._check_graph_whole_recurse(n, up=True)
        for n in start_node.downstream_nodes:
            n.seen = True
            self._check_graph_whole_recurse(n, up=False)
        # Now check if there are any nodes in the graph that have not been seen
        disjointed_node_ids = [str(n.id) for n in self.nodes if not n.seen]
        self._unsee()
        if disjointed_node_ids:
            raise CompileException({
                'node_ids': disjointed_node_ids,
                'reason': CompileErrorReason.DISJOINTED_GRAPH.camel(),
                'errors': 'The graph must be connected. If you are not using a node, disconnect it from all other nodes. The graph ignores fully disconnected nodes.'
            })
            

    def _check_graph_whole_recurse(self, node: DagNode, up: bool):
        if up:
            nodes = node.upstream_nodes
        else:
            nodes = node.downstream_nodes
        for n in nodes:
            n.seen = True
            self._check_graph_whole_recurse(n, up=up)


    def construct_keras(self):
        if not self.edges:
            raise DagException("The graph has no connections")
        self._check_graph_whole()

        model_file = "##~ Model code generated by MAI: DO NOT TOUCH! ~Mai\n\n"
        model_file += "import tensorflow as tf\n"
        model_file += "import keras\n"
        model_file += "from keras import layers\n\n"

        for head in self.get_head_nodes():
            head.seen = True
            model_file += head.code_gen() + '\n'
            model_file += self._construct_keras(head)

        self._unsee(construct=True)
        return model_file


    def _construct_keras(self, node: DagNode):
        model_file = ''
        for n in node.downstream_nodes:
            upstream_loaded = True
            for upstream_node in n.upstream_nodes:
                if not upstream_node.seen:
                    upstream_loaded = False
            if upstream_loaded:
                n.seen = True
                model_file += n.code_gen() + '\n'
                model_file += self._construct_keras(n)

        return model_file + '\n'


