import abc
from python.directed_acyclic_graph import LayerSettings, Layer


class InputSettings(LayerSettings):
    shape: list[int]
    # dtype: Optional[Dtype]


class Input(Layer, metaclass=abc.ABCMeta):
    settings_validator = InputSettings

    @property
    def min_upstream_nodes() -> int:
        return 0

    @property
    def type() -> str:
        return 'input'

    