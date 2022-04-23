import abc
from uuid import uuid4


class Layer(metaclass=abc.ABCMeta):
    type: str = 'base_layer'

    def __init__(self):
        self.layer_id = uuid4()

    @abc.abstractmethod
    def generate_code_line(self):
        raise NotImplementedError()

    