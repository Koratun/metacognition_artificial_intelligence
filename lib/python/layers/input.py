from typing import Optional
from python.layers.utils import Dtype
from python.directed_acyclic_graph import NamedLayerSettings, Layer, DagNode, CompileException, CompileErrorReason
from pydantic import StrictInt, ValidationError


class InputSettings(NamedLayerSettings):
    shape: tuple[Optional[StrictInt], ...]
    dtype: Optional[Dtype] = None


class Input(Layer):
    settings_validator = InputSettings
    type = 'input'
    max_upstream_nodes = 2

    def generate_code_line(self, node_being_built: DagNode) -> str:
        if self.constructed:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': "This Input node has already been constructed, you cannot construct an input twice."
            })
        try:
            line = self.name + f' = {self.keras_module_location}.{self.__class__.__name__}(' + self.construct_settings() + ')'
            self.constructed = True
            return line
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.SETTINGS_VALIDATION.camel(), 
                'errors': e.errors()
            })