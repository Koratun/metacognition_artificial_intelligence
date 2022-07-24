from typing import Optional
from python.layers.utils import Dtype
from python.layers.output import Output
from python.layers.datasources_and_preprocessing import datasources, preprocessing
from python.directed_acyclic_graph import (
    NamedLayerSettings,
    Layer,
    DagNode,
    CompileException,
    CompileErrorReason,
)
from pydantic import StrictInt, ValidationError


class InputSettings(NamedLayerSettings):
    shape: tuple[Optional[StrictInt], ...]
    dtype: Optional[Dtype] = None


class Input(Layer):
    settings_validator = InputSettings
    type = "input"
    max_upstream_nodes = 2

    def validate_connected_upstream(self, node: "DagNode"):
        if (
            node.layer.__class__ not in (datasources.KerasDatasource, Output)
            and not isinstance(node.layer, preprocessing.PreprocessingLayer)
            and node.layer.__class__.__name__ != "Compile"
        ):
            return "Only preprocessing layers, datasources, and other models can feed into the Input node."

    def generate_code_line(self, node_being_built: DagNode) -> str:
        if self.constructed:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.COMPILATION_VALIDATION,
                    "errors": "This Input node has already been constructed, you cannot construct an input twice.",
                }
            )
        try:
            line = (
                self.name
                + f" = {self.keras_module_location}.{self.__class__.__name__}("
                + self.construct_settings()
                + ")"
            )
            self.constructed = True
            return line
        except ValidationError as e:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.SETTINGS_VALIDATION,
                    "errors": e.errors(),
                }
            )
