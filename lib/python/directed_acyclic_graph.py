from uuid import UUID, uuid4
from enum import Enum
from typing import Type, Optional, Literal
import re
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

    # Values must be in camelCase to transfer to dart properly
    UPSTREAM_NODE_COUNT = "upstreamNodeCount"
    DOWNSTREAM_NODE_COUNT = "downstreamNodeCount"
    SETTINGS_VALIDATION = "settingsValidation"
    COMPILATION_VALIDATION = "compilationValidation"
    INPUT_MISSING = "inputMissing"
    DISJOINTED_GRAPH = "disjointedGraph"


class CompileException(Exception):
    def __init__(self, error_data: dict, *args: object) -> None:
        self.error_data = error_data
        super().__init__(error_data, *args)


class LayerSettings(BaseModel):
    @validator("*", pre=True)
    def string_validator(cls, v, field: ModelField):
        if v == "":
            return None
        if (
            field.type_ is str
            or field.type_ is UUID
            or getattr(field.outer_type_, "__origin__", None) is Literal
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

    @validator("name")
    def snakecase(cls, v):
        if re.search(r"^[^a-z]|[^a-z0-9_]", v):
            raise ValueError(f"Name must adhere to python variable naming conventions (snake_case).")


class Layer:
    settings_validator: Type[LayerSettings] = None
    type = "base_layer"
    keras_module_location = "layers"
    min_upstream_nodes = 1
    max_upstream_nodes = 1
    min_downstream_nodes = 1
    max_downstream_nodes = 1

    def __init__(self):
        self.layer_id = uuid4()
        self.constructed = False
        self.settings_data = self.get_settings_data_fields()

    @classmethod
    def get_settings_data_fields(cls) -> dict[str, str]:
        response: dict[str, dict] = cls.settings_validator.schema()["properties"]
        default_fields = {}
        for k, v in response.items():
            if k == "name":
                default_fields[k] = cls.type
            elif "default" in v:
                default_fields[k] = str(v["default"])
            else:
                default_fields[k] = ""
        return default_fields

    @property
    def name(self):
        return self.settings_data["name"]

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

    def validate_nodestreams(self, node_being_built: "DagNode"):
        if not self.valid_number_downstream_nodes(len(node_being_built.downstream_nodes)):
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.DOWNSTREAM_NODE_COUNT,
                    "errors": f"{self.__class__.__name__} downstream node count does not meet requirements: "
                    f"{self.min_downstream_nodes} <= {len(node_being_built.downstream_nodes)} <= {self.max_downstream_nodes}",
                }
            )
        if not self.valid_number_upstream_nodes(len(node_being_built.upstream_nodes)):
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.UPSTREAM_NODE_COUNT,
                    "errors": f"{self.__class__.__name__} upstream node count does not meet requirements: "
                    f"{self.min_upstream_nodes} <= {len(node_being_built.upstream_nodes)} <= {self.max_upstream_nodes}",
                }
            )

    def validate_connected_downstream(self, node: "DagNode"):
        return None

    def validate_connected_upstream(self, node: "DagNode"):
        return None

    def construct_settings(self):
        set_settings: dict = self.settings_validator(**self.settings_data).dict(exclude_defaults=True, exclude={"name"})
        return ", ".join(f"{k}={v}" for k, v in set_settings.items())

    def generate_code_line(self, node_being_built: "DagNode") -> str:
        """
        Generate the code line for this layer.
        It must validate the syntax first before continuing.
        It must set the `constructed` attribute to True.
        """
        try:
            if self.constructed:
                line = self.name + " = " + self.name
            else:
                line = (
                    self.name
                    + f" = {self.keras_module_location}.{self.__class__.__name__}("
                    + self.construct_settings()
                    + ")"
                )
                self.constructed = True
            line += "(" + node_being_built.upstream_nodes[0].layer.name + ")"
            return line
        except ValidationError as e:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.SETTINGS_VALIDATION,
                    "errors": e.errors(),
                }
            )


class Compile(Layer):
    settings_validator = LayerSettings
    min_upstream_nodes = 3
    max_upstream_nodes = inf
    min_downstream_nodes = 0
    max_downstream_nodes = inf

    def __init__(self):
        super().__init__()
        self.output: DagNode = None
        self.loss: DagNode = None
        self.optimizer: DagNode = None
        self.metrics: list[DagNode] = []

    @property
    def name(self):
        # This should only ever be accessed when constructing the graph.
        # If it is accessed outside this context, there is a good chance
        # that python will spew out a NoneType access error
        return self.output.layer.name

    def validate_connected_downstream(self, node: "DagNode"):
        if node.layer.__class__.__name__ not in ["Input", "Fit"]:
            return "Compile must be the last node in the graph or feed into an Input node."

    def validate_connected_upstream(self, node: "DagNode"):
        if node.layer.__class__.__name__ != "Output" and not isinstance(node.layer, CompileArgLayer):
            return "Only Output, Loss, Optimizer, and Metric nodes may connect to a compile node."

    def connect_special_node(self, node: "DagNode"):
        if isinstance(node.layer, Loss):
            if self.loss:
                return "A model can only have one loss"
            self.loss = node
        elif isinstance(node.layer, Optimizer):
            if self.optimizer:
                return "A model can only have one optimizer"
            self.optimizer = node
        elif isinstance(node.layer, Metric):
            self.metrics.append(node)
        else:
            if self.output:
                return "A Compile node can only receive one Output node"
            self.output = node

    def disconnect_special_node(self, node: "DagNode"):
        if isinstance(node.layer, Loss):
            self.loss = None
        elif isinstance(node.layer, Optimizer):
            self.optimizer = None
        elif isinstance(node.layer, Metric):
            self.metrics.remove(node)
        else:
            self.output = None

    def generate_code_line(self, node_being_built: "DagNode") -> str:
        if self.constructed:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.COMPILATION_VALIDATION,
                    "errors": "This compile node has already been constructed, you cannot compile a model twice.",
                }
            )
        # Perform validation
        errors = []
        if not self.loss:
            errors.append("No loss found")
        if not self.optimizer:
            errors.append("No optimizer found")
        if not self.output:
            errors.append("No model attached to this compile node")
        if errors:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.COMPILATION_VALIDATION,
                    "errors": "; ".join(errors),
                }
            )

        line = f"{self.name}.compile("
        line += f"\n\toptimizer={self.optimizer.code_gen()}, "
        line += f"\n\tloss={self.loss.code_gen()}, "
        line += f"\n\tmetrics=[{', '.join(n.code_gen() for n in self.metrics)}]\n)"
        self.constructed = True
        return line


# These classes would normally go inside the compilation folder,
# but they are here to prevent circular import errors.
class CompileArgLayer(Layer):
    min_upstream_nodes = 0
    max_upstream_nodes = 0

    def validate_connected_downstream(self, node: "DagNode"):
        if not isinstance(node.layer, Compile):
            return "Compile arguments can only be connected to a Compile node."

    def generate_code_line(self, node_being_built: "DagNode") -> str:
        if not isinstance(node_being_built.downstream_nodes[0].layer, Compile):
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.COMPILATION_VALIDATION,
                    "errors": "Compile arguments must be connected to a Compile layer.",
                }
            )

        line = f"{self.keras_module_location}.{self.__class__.__name__}({self.construct_settings()})"
        return line


class Metric(CompileArgLayer):
    keras_module_location = "metrics"


class Loss(Metric):
    keras_module_location = "losses"


class Optimizer(CompileArgLayer):
    keras_module_location = "optimizers"


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

    def connect_to(self, node: "DagNode"):
        self.add_downstream_node(node)
        node.add_upstream_node(self)

    def disconnect_from(self, node: "DagNode"):
        self.remove_downstream_node(node)
        node.remove_upstream_node(self)

    def check_upstream_node_connection_limits(self):
        return len(self.upstream_nodes) <= self.layer.max_upstream_nodes

    def check_downstream_node_connection_limits(self):
        return len(self.downstream_nodes) <= self.layer.max_downstream_nodes

    def add_upstream_node(self, node: "DagNode"):
        self.upstream_nodes.append(node)

    def add_downstream_node(self, node: "DagNode"):
        self.downstream_nodes.append(node)

    def remove_upstream_node(self, node: "DagNode"):
        self.upstream_nodes.remove(node)

    def remove_downstream_node(self, node: "DagNode"):
        self.downstream_nodes.remove(node)


# This import is down here to avoid circular import errors
from python.layers.compilation.fit import Fit


class DirectedAcyclicGraph:
    def __init__(self, loadpath: str = None):
        self.nodes: list[DagNode] = []
        self.edges: list[tuple[DagNode, DagNode]] = []
        self.fit_node = self.add_node(Fit())

        if loadpath:
            self.load(loadpath)

    @contextmanager
    def _unsee(self, last_node_id: UUID = None):
        if last_node_id:
            # Temporarily connect the fit node with the last node
            self.connect_nodes(last_node_id, self.fit_node.id)
        yield
        for n in self.nodes:
            n.seen = False
            if last_node_id:
                n.layer.reset_construct()
        if last_node_id:
            self.disconnect_nodes(last_node_id, self.fit_node.id)

    def get_head_nodes(self) -> list[DagNode]:
        with self._unsee():
            for e in self.edges:
                e[1].seen = True
            head_nodes = [
                n
                for n in self.nodes
                if not n.seen
                and not isinstance(n.layer, CompileArgLayer)
                and (len(n.upstream_nodes) > 0 or len(n.downstream_nodes) > 0)
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
            if heads := (
                self.get_head_nodes()
                + [n for n in self.nodes if isinstance(n.layer, CompileArgLayer) and n.downstream_nodes]
            ):
                for head in heads:
                    head.seen = True
                    if not self._check_acyclic(head):
                        return False
            else:
                return False
            cyclic = (
                len(
                    [n for n in self.nodes if not n.seen and (len(n.upstream_nodes) > 0 or len(n.downstream_nodes) > 0)]
                )
                == 0
            )
            return cyclic

    def _check_acyclic(self, node: DagNode) -> bool:
        for n in node.downstream_nodes:
            upstream_seen = True
            for upstream_node in n.upstream_nodes:
                if not upstream_node.seen:
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
            elif error := source_node.layer.validate_connected_downstream(dest_node):
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException(error)
            elif error := dest_node.layer.validate_connected_upstream(source_node):
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException(error)
            if isinstance(dest_node.layer, Compile):
                if error := dest_node.layer.connect_special_node(source_node):
                    self.edges.pop()
                    source_node.disconnect_from(dest_node)
                    raise DagException(error)

    def disconnect_nodes(self, source_id: UUID, dest_id: UUID):
        source_node, dest_node = self.get_node(source_id), self.get_node(dest_id)
        if (source_node, dest_node) in self.edges:
            self.edges.remove((source_node, dest_node))
            source_node.disconnect_from(dest_node)
            if isinstance(dest_node.layer, Compile):
                dest_node.layer.disconnect_special_node(source_node)
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
                self._check_graph_whole_recurse(n, up=False)
            for n in start_node.downstream_nodes:
                n.seen = True
                self._check_graph_whole_recurse(n, up=False)
                self._check_graph_whole_recurse(n, up=True)
            # Now check if there are any nodes in the graph that have not been seen
            disjointed_node_ids = [
                str(n.id)
                for n in self.nodes
                if not n.seen and (len(n.upstream_nodes) > 0 or len(n.downstream_nodes) > 0)
            ]
            if disjointed_node_ids:
                raise CompileException(
                    {
                        "node_ids": disjointed_node_ids,
                        "reason": CompileErrorReason.DISJOINTED_GRAPH,
                        "errors": "The graph must be connected. If you are not using a node, disconnect it from all other nodes. The graph ignores fully disconnected nodes.",
                    }
                )

        # Get tail nodes (It is an error if there is more than 1)
        # and it shouldn't be possible for there to be 0 tail nodes
        with self._unsee():
            for e in self.edges:
                e[0].seen = True
            tail_nodes = [
                n for n in self.nodes if not n.seen and (len(n.upstream_nodes) > 0 or len(n.downstream_nodes) > 0)
            ]
            if len(tail_nodes) != 1:
                raise CompileException(
                    {
                        "node_ids": [str(n.id) for n in tail_nodes],
                        "reason": CompileErrorReason.DISJOINTED_GRAPH,
                        "errors": "The graph must only have one final node.",
                    }
                )
            return tail_nodes[0]

    def _check_graph_whole_recurse(self, node: DagNode, up: bool):
        if up:
            nodes = node.upstream_nodes
        else:
            nodes = node.downstream_nodes
        for n in nodes:
            if n.seen is True:
                continue
            n.seen = True
            self._check_graph_whole_recurse(n, up=up)
            self._check_graph_whole_recurse(n, up=not up)

    def construct_keras(self):
        if not self.edges:
            raise DagException("The graph has no connections")
        last_node = self._check_graph_whole()

        # The final node must be a compile node
        if not isinstance(last_node.layer, Compile):
            raise DagException("The graph must end with a Compile node")

        heads = self.get_head_nodes()
        if not heads:
            raise DagException("Graph needs more than a compile layer!")

        model_file = "##~ Model code generated by MAI: DO NOT TOUCH! ~Mai\n\n"
        model_file += "import numpy as np\n"
        model_file += "import tensorflow as tf\n"
        model_file += "import keras\n"
        model_file += "from keras import layers, losses, optimizers, metrics, callbacks\n\n"

        with self._unsee(last_node_id=last_node.id):
            for head in heads:
                head.seen = True
                model_file += head.code_gen() + "\n"
                model_file += self._construct_keras(head)

        return model_file.rstrip()

    def _construct_keras(self, node: DagNode):
        model_file = ""
        for n in node.downstream_nodes:
            upstream_loaded = True
            for upstream_node in n.upstream_nodes:
                if not upstream_node.seen and not isinstance(upstream_node.layer, CompileArgLayer):
                    upstream_loaded = False
            if upstream_loaded:
                n.seen = True
                model_file += n.code_gen() + "\n"
                model_file += self._construct_keras(n)

        return model_file + "\n"

    def save(self, gui_locations: dict[UUID, list[float]]):
        file = ""

        def _escape(s: str):
            return s.replace("\\", "\\\\").replace(",", "\\,")

        for n in self.nodes:
            file += (
                n.layer.__class__.__name__
                + "("
                + ",".join(f"{k}={_escape(v)}" for k, v in n.layer.settings_data.items())
                + f")<{n.id}>"
                + ("(" + ",".join(str(v) for v in loc) + ")" if (loc := gui_locations.get(n.id)) else "")
                + "\n"
            )

        file += "<->\n"
        for e in self.edges:
            file += f"<{e[0].id}><{e[1].id}>\n"

        return file

    def load(self, filepath: str):
        from python.layers import layer_classes

        with open(filepath, "r") as f:
            data = f.read().splitlines()

        def _unescape(s: str):
            return s.replace("\\,", ",").replace("\\\\", "\\")

        gui_locations = {}
        connecting = False
        for entry in data:
            if entry == "<->":
                connecting = True
                continue

            if not connecting:
                layer_str = entry[: entry.find("(")]
                layer = layer_classes[layer_str]()

                settings_strs = re.split(r"[^\\],", entry[entry.find("(") + 1 : entry.rfind(")<")])
                settings = {kv[0]: _unescape(kv[1]) for s in settings_strs for kv in s.split("=", maxsplit=1)}

                layer.settings_data = settings

                node_id = UUID(entry[entry.rfind("<") + 1 : entry.rfind(">")])

                if layer_str == "Fit":
                    self.fit_node.layer = layer
                    self.fit_node.id = node_id
                else:
                    node = self.add_node(layer)
                    node.id = node_id

                if entry[-2] == ")":
                    gui_locations[node_id] = entry[entry.rfind("(") + 1 : -2].split(",")
            else:
                source_id = UUID(entry[entry.find("<") + 1 : entry.find(">")])
                dest_id = UUID(entry[entry.rfind("<") + 1 : entry.rfind(">")])
                self.connect_nodes(source_id, dest_id)
