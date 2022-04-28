from uuid import uuid4
import abc
from typing import Type
from uuid import uuid4
from wsgiref.validate import validator
from pydantic import BaseModel, ValidationError
from pydantic.schema import schema as get_schema


class LayerSyntaxException(Exception):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)


class LayerSettings(BaseModel):
    @validator('*', always=True)
    def null_string_validator(cls, v):
        if v == '':
            return None
        return v


class Layer(metaclass=abc.ABCMeta):
    def __init__(self):
        self.layer_id = uuid4()
        self.name = self.type
        self.constructed = False
        self.settings_validator: Type[LayerSettings] = None

    def make_settings_data_fields(self, validator: Type[LayerSettings]):
        self.settings_validator = validator
        response = get_schema([validator])['definitions']
        response: dict = response[validator.__name__]['properties']
        self.settings_data = {k: '' for k in response.keys()}

    def update_settings(self, settings: dict):
        """This method assumes that the settings match this layer's schema"""
        self.settings_data.update(settings)
        return self.validate_settings()

    def validate_settings(self):
        try:
            self.settings_validator(self.settings_data)
        except ValidationError as e:
            return e.errors()

    def reset_construct(self):
        self.constructed = False

    @property
    def min_upstream_nodes() -> int:
        return 1

    @property
    def max_upstream_nodes() -> int:
        return 1

    def check_number_upstream_nodes(self, n: int) -> bool:
        return self.min_upstream_nodes <= n and n <= self.max_upstream_nodes 

    @property
    def min_downstream_nodes() -> int:
        return 1

    @property
    def max_downstream_nodes() -> int:
        return 1

    def check_number_downstream_nodes(self, n: int) -> bool:
        return self.min_downstream_nodes <= n and n <= self.max_downstream_nodes 

    @property
    @abc.abstractmethod
    def type() -> str:
        return 'base_layer'

    def validate_syntax(self, node_being_built: 'DagNode'):
        errors = {}
        errors['setting_errors'] = self.validate_settings()
        errors['node_errors'] = []
        if not self.check_number_upstream_nodes(len(node_being_built.upstream_nodes)):
            errors['node_errors'].append('upstream count out of bounds')
        if not self.check_number_downstream_nodes(len(node_being_built.downstream_nodes)):
            errors['node_errors'].append('downstream count out of bounds')
        return {k: v for k, v in errors.items() if v}

    @abc.abstractmethod
    def generate_code_line(self, node_being_built: 'DagNode') -> str:
        """
        Generate the code line for this layer.
        This method must be implemented by the subclasses.
        It must validate the syntax first before continuing.
        It must set the `constructed` attribute to True.
        """
        raise NotImplementedError()


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
        self.inputs: list[DagNode] = []


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


    def get_node(self, node_id: uuid4) -> DagNode:
        for n in self.nodes:
            if n.id == node_id:
                return n
        raise DagException("Node not found")


    def _is_acyclic(self) -> bool:
        if len(self.edges) < 2:
            return True
        for head in self.get_head_nodes():
            head.seen = True
            if not self._is_acyclic(head):
                head.seen = False
                return False
            head.seen = False
        return True

    
    def _is_acyclic(self, node: DagNode) -> bool:
        for n in node.downstream_nodes:
            if n.seen:
                return False
            n.seen = True
            if not self._is_acyclic(n):
                n.seen = False
                return False
            n.seen = False
        return True


    def connect_nodes(self, source_node: DagNode, dest_node: DagNode):
        if (source_node, dest_node) in self.edges:
            raise DagException("Connection already exists")
        else:
            self.edges.append((source_node, dest_node))
            source_node.connect_to(dest_node)
            if not self._is_acyclic():
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Circular graphs not allowed")


    def disconnect_nodes(self, source_node: DagNode, dest_node: DagNode):
        if (source_node, dest_node) in self.edges:
            self.edges.remove((source_node, dest_node))
            source_node.disconnect_from(dest_node)


    def add_node(self, layer: Layer) -> DagNode:
        node = DagNode(layer)
        if not node in self.nodes:
            if layer.type == 'input':
                self.inputs.append(node)
            self.nodes.append(node)
            return node
        else:
            raise DagException("Node already added")


    def remove_node(self, node: DagNode):
        for e in list(self.edges):
            if node in e:
                self.edges.remove(e)
        self.nodes.remove(node)


    def construct_keras(self):
        if not self.edges:
            raise DagException("The graph has no connections")

        model_file = "##~ Model code generated by MAI: DO NOT TOUCH! ~Mai\n\n"

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


