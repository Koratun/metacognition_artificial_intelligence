from uuid import UUID, uuid4
from enum import Enum
from typing import Type, Optional, Literal
import re
from humps import camelize
from contextlib import contextmanager
from pydantic import BaseModel, ValidationError, validator
from pydantic.fields import ModelField
from math import inf



# This class would normally go inside the schemas file, 
# but it is here to prevent circular import errors
class CompileErrorReason(Enum):
    """
    The reason why a layer failed to construct.
    """
    UPSTREAM_NODE_COUNT = 'upstream_node_count'
    DOWNSTREAM_NODE_COUNT = 'downstream_node_count'
    SETTINGS_VALIDATION = 'settings_validation'
    COMPILATION_VALIDATION = 'compilation_validation'
    INPUT_MISSING = 'input_missing'
    DISJOINTED_GRAPH = 'disjointed_graph'

    def camel(self) -> str:
        return camelize(self.value)


class CompileException(Exception):
    def __init__(self, error_data: dict, *args: object) -> None:
        self.error_data = error_data
        super().__init__(error_data, *args)


class LayerSettings(BaseModel):
    @validator('*', pre=True)
    def string_validator(cls, v, field: ModelField):
        if v == '':
            return None
        if (field.type_ is str 
            or field.type_ is UUID
            or getattr(field.outer_type_, '__origin__', None) is Literal
            or issubclass(field.outer_type_, Enum)
        ):
            return v
        try:
            # The empty dictionary is to prevent security threats 
            # in the form of injection attacks
            return eval(v, {})
        except Exception:
            raise ValueError(f"Invalid formatting: '{v}'")


class NamedLayerSettings(LayerSettings):
    name: str

    @validator('name')
    def snakecase(cls, v):
        if re.search(r"^[^a-z]|[^a-z0-9_]", v):
            raise ValueError(f"Name must adhere to python variable naming conventions (snake_case).")


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
        self.constructed = False
        self.settings_data = self.get_settings_data_fields()

    @classmethod
    def get_settings_data_fields(cls) -> dict:
        response: dict[str, dict] = cls.settings_validator.schema()['properties']
        default_fields = {}
        for k, v in response.items():
            if k == 'name':
                default_fields[k] = cls.type
            elif 'default' in v:
                default_fields[k] = str(v['default'])
            else:
                default_fields[k] = ''
        return default_fields

    @property
    def name(self):
        return self.settings_data['name']

    def update_settings(self, settings: dict[str, str]):
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

    def valid_number_upstream_nodes(self, n: int) -> bool:
        return self.min_upstream_nodes <= n and n <= self.max_upstream_nodes 

    def valid_number_downstream_nodes(self, n: int) -> bool:
        return self.min_downstream_nodes <= n and n <= self.max_downstream_nodes 

    def validate_nodestreams(self, node_being_built: 'DagNode'):
        if not self.valid_number_downstream_nodes(len(node_being_built.downstream_nodes)):
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.DOWNSTREAM_NODE_COUNT.camel(), 
                'errors': f'{self.__class__.__name__} downstream node count does not meet requirements: '
                f'{self.min_downstream_nodes} <= {len(node_being_built.downstream_nodes)} <= {self.max_downstream_nodes}'
            })
        if not self.valid_number_upstream_nodes(len(node_being_built.upstream_nodes)):
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.UPSTREAM_NODE_COUNT.camel(), 
                'errors': f'{self.__class__.__name__} upstream node count does not meet requirements: '
                f'{self.min_upstream_nodes} <= {len(node_being_built.upstream_nodes)} <= {self.max_upstream_nodes}'
            })

    def construct_settings(self):
        set_settings: dict = self.settings_validator(**self.settings_data).dict(exclude_defaults=True, exclude={'name'})
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
                line = self.name + f' = {self.keras_module_location}.{self.__class__.__name__}(' + self.construct_settings() + ')'
                self.constructed = True
            line += '(' + node_being_built.upstream_nodes[0].layer.name + ')'
            return line
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.SETTINGS_VALIDATION.camel(), 
                'errors': e.errors()
            })


class CompileSettings(LayerSettings):
    output_node_id: UUID
    loss_node_id: UUID
    optimizer_node_id: UUID
    metric_node_ids: Optional[list[UUID]]


class Compile(Layer):
    settings_validator = CompileSettings
    type = 'compile'
    min_upstream_nodes = 3
    max_upstream_nodes = inf
    max_downstream_nodes = inf

    def __init__(self):
        super().__init__()
        self.output: DagNode = None
        self.loss: DagNode = None
        self.optimizer: DagNode = None

    @property
    def name(self):
        # This should only ever be accessed when constructing the graph.
        # If it is accessed outside this context, there is a good chance
        # that python will spew out a NoneType access error
        return self.output.layer.name

    def generate_code_line(self, node_being_built: 'DagNode') -> str:
        if self.constructed:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': "This compile node has already been constructed, you cannot compile a model twice."

            })
        try:
            # Perform setting validation
            node_connections: CompileSettings = self.settings_validator(**self.settings_data)
            # We can assume that all the nodes are of the correct types and that
            # the three necessary nodes (out, loss, opt) are present since validation
            # has already passed. The Frontend will make sure that only nodes of the correct
            # type can be attached to the compile layer.
            metrics: list[DagNode] = []
            for n in node_being_built.upstream_nodes:
                n.seen = True
                if n.id == node_connections.output_node_id:
                    self.output = n
                elif n.id == node_connections.loss_node_id:
                    self.loss = n
                elif n.id == node_connections.optimizer_node_id:
                    self.optimizer = n
                elif n.id in node_connections.metric_node_ids:
                    metrics.append(n)

            line = f"{self.output.layer.name}.compile("
            line += f"\n\toptimizer={self.optimizer.code_gen()}, "
            line += f"\n\tloss={self.loss.code_gen()}, "
            line += f"\n\tmetrics=[{', '.join(n.code_gen() for n in metrics)}]\n)"
            self.constructed = True
            return line
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': e.errors()
            })


# These classes would normally go inside the compilation folder, 
# but they are here to prevent circular import errors.
class CompileArgLayer(Layer):
    min_upstream_nodes = 0
    max_upstream_nodes = 0
    def generate_code_line(self, node_being_built: 'DagNode') -> str:
        if not self.check_number_downstream_nodes(len(node_being_built.downstream_nodes)):
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.DOWNSTREAM_NODE_COUNT.camel(), 
                'errors': 'Layer downstream node count does not meet requirements: '
                f'{self.min_downstream_nodes} <= {len(node_being_built.downstream_nodes)} <= {self.max_downstream_nodes}'
            })
        if not self.check_number_upstream_nodes(len(node_being_built.upstream_nodes)):
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.UPSTREAM_NODE_COUNT.camel(), 
                'errors': 'Layer upstream node count does not meet requirements: '
                f'{self.min_upstream_nodes} <= {len(node_being_built.upstream_nodes)} <= {self.max_upstream_nodes}'
            })
        if not isinstance(node_being_built.downstream_nodes[0].layer, Compile):
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': "Compile arguments must be connected to a Compile layer."
            })
        
        line = f"{self.keras_module_location}.{self.__class__.__name__}({self.construct_settings()})"
        return line

class Metric(CompileArgLayer):
    keras_module_location = 'metrics'


class Loss(Metric):
    keras_module_location = 'losses'

   


class Optimizer(CompileArgLayer):
    keras_module_location = 'optimizers'


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
        self.layer.validate_nodestreams(self)
        return self.layer.generate_code_line(self)

    def connect_to(self, node: 'DagNode'):
        self.add_downstream_node(node)
        node.add_upstream_node(self)

    def disconnect_from(self, node: 'DagNode'):
        self.remove_downstream_node(node)
        node.remove_upstream_node(self)

    def check_upstream_node_connection_limits(self):
        return len(self.upstream_nodes) <= self.layer.max_upstream_nodes

    def check_downstream_node_connection_limits(self):
        return len(self.downstream_nodes) <= self.layer.max_downstream_nodes

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


    @contextmanager
    def _unsee(self, construct=False):
        yield
        for n in self.nodes:
            n.seen = False
            if construct:
                n.layer.reset_construct()


    def get_head_nodes(self) -> list[DagNode]:
        with self._unsee():
            for e in self.edges:
                e[1].seen = True
            head_nodes = [
                n for n in self.nodes 
                if not n.seen 
                    and not isinstance(n.layer, CompileArgLayer) 
                    and (n.upstream_nodes or n.downstream_nodes)
            ]
        return head_nodes


    def get_node(self, node_id: UUID) -> DagNode:
        for n in self.nodes:
            if n.id == node_id:
                return n
        raise DagException("Node not found")


    def check_acyclic(self) -> bool:
        if len(self.edges) < 1:
            return True
        with self._unsee():
            if heads := (self.get_head_nodes() + 
                [n for n in self.nodes 
                if isinstance(n.layer, CompileArgLayer) 
                    and n.downstream_nodes]
            ):
                for head in heads:
                    head.seen = True
                    if not self._check_acyclic(head):
                        return False
            else:
                return False
            cyclic = len([
                n for n in self.nodes 
                if not n.seen 
                    and (n.upstream_nodes or n.downstream_nodes)
            ]) == 0
            return cyclic


    def _check_acyclic(self, node: DagNode) -> bool:
        for n in node.downstream_nodes:
            upstream_seen = True
            for upstream_node in n.upstream_nodes:
                if not upstream_node.seen and not isinstance(upstream_node.layer, CompileArgLayer):
                    upstream_seen = False
            if not upstream_seen:
                return True

            if n.seen:
                return False
            n.seen = True
            if not self._check_acyclic(n):
                return False
        return True


    def connect_nodes(self, source_id: UUID, dest_id: UUID):
        source_node, dest_node = self.get_node(source_id), self.get_node(dest_id)
        if (source_node, dest_node) in self.edges:
            raise DagException("Connection already exists")
        else:
            self.edges.append((source_node, dest_node))
            source_node.connect_to(dest_node)
            if not source_node.check_downstream_node_connection_limits():
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Source node has too many outgoing connections")
            elif not dest_node.check_upstream_node_connection_limits():
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Destination node has too many incoming connections")
            elif not self.check_acyclic(): 
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


    def _check_graph_whole(self) -> DagNode:
        with self._unsee():
            start_node = self.edges[0][0]
            start_node.seen = True
            for n in start_node.upstream_nodes:
                n.seen = True
                self._check_graph_whole_recurse(n, up=True)
            for n in start_node.downstream_nodes:
                n.seen = True
                self._check_graph_whole_recurse(n, up=False)
            # Now check if there are any nodes in the graph that have not been seen
            disjointed_node_ids = [
                str(n.id) for n in self.nodes 
                if not n.seen and (n.upstream_nodes or n.downstream_nodes)
            ]
            if disjointed_node_ids:
                raise CompileException({
                    'node_ids': disjointed_node_ids,
                    'reason': CompileErrorReason.DISJOINTED_GRAPH.camel(),
                    'errors': 'The graph must be connected. If you are not using a node, disconnect it from all other nodes. The graph ignores fully disconnected nodes.'
                })
        
        # Get tail nodes (It is an error if there is more than 1)
        # and it shouldn't be possible for there to be 0 tail nodes
        with self._unsee():
            for e in self.edges:
                e[0].seen = True
            tail_nodes = [
                n for n in self.nodes 
                if not n.seen and (n.upstream_nodes or n.downstream_nodes)
            ]
            if len(tail_nodes) != 1:
                raise CompileException({
                    'node_ids': [str(n.id) for n in tail_nodes],
                    'reason': CompileErrorReason.DISJOINTED_GRAPH.camel(),
                    'errors': 'The graph must only have one final node.'
                })
            return tail_nodes[0]
            

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
        last_node = self._check_graph_whole()

        model_file = "##~ Model code generated by MAI: DO NOT TOUCH! ~Mai\n\n"
        model_file += "import numpy as np\n"
        model_file += "import tensorflow as tf\n"
        model_file += "import keras\n"
        model_file += "from keras import layers, losses, optimizers, metrics, callbacks\n\n"

        with self._unsee(construct=True):
            for head in self.get_head_nodes():
                head.seen = True
                model_file += head.code_gen() + '\n'
                model_file += self._construct_keras(head)
        return model_file.rstrip()


    def _construct_keras(self, node: DagNode):
        model_file = ''
        for n in node.downstream_nodes:
            upstream_loaded = True
            for upstream_node in n.upstream_nodes:
                if not upstream_node.seen and not isinstance(upstream_node.layer, CompileArgLayer):
                    upstream_loaded = False
            if upstream_loaded:
                n.seen = True
                model_file += n.code_gen() + '\n'
                model_file += self._construct_keras(n)

        return model_file + '\n'


