import abc
from uuid import uuid4

from lib.python.directed_acyclic_graph import DagNode


class Layer(metaclass=abc.ABCMeta):
    type: str = 'base_layer'

    def __init__(self):
        self.layer_id = uuid4()
        self.name = self.type
        self.constructed = False

    def reset_construct(self):
        self.constructed = False

    @abc.abstractmethod
    def generate_code_line(self, node_being_built: DagNode) -> str:
        """
        Generate the code line for this layer.
        This method must be implemented by the subclasses.
        It must set the `constructed` attribute to True.
        """
        raise NotImplementedError()

    