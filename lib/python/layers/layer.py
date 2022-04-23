import abc
from uuid import uuid4
from pydantic import BaseModel

from lib.python.directed_acyclic_graph import DagNode


class LayerSyntaxException(Exception):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)


class Layer(metaclass=abc.ABCMeta):
    def __init__(self):
        self.layer_id = uuid4()
        self.name = self.type
        self.constructed = False
        self.settings: BaseModel = None

    def reset_construct(self):
        self.constructed = False

    @property
    @abc.abstractmethod
    def type() -> str:
        return 'base_layer'

    @abc.abstractmethod
    def validate_syntax(self, node_being_built: DagNode):
        """
        This method must check if the settings and node 
        connections are correct for this layer.
        """
        raise LayerSyntaxException("Not implemented")

    @abc.abstractmethod
    def generate_code_line(self, node_being_built: DagNode) -> str:
        """
        Generate the code line for this layer.
        This method must be implemented by the subclasses.
        It must validate the syntax first before continuing.
        It must set the `constructed` attribute to True.
        """
        raise NotImplementedError()

    