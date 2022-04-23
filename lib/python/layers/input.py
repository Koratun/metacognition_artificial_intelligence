from pydantic import BaseModel
from layer import Layer
from lib.python.directed_acyclic_graph import DagNode


class InputSettings(BaseModel):
    shape: list[int]


class Input(Layer):
    def __init__(self):
        super().__init__()
        self.settings = InputSettings()
        

    @property
    def type() -> str:
        return 'input'

    # def validate_syntax(self, node_being_built: DagNode):
        
