import abc
from python.directed_acyclic_graph import LayerSettings, Layer


class InputSettings(LayerSettings):
    shape: list[int]
    # dtype: Optional[Dtype]


class Input(Layer, metaclass=abc.ABCMeta):
    def __init__(self):
        super().__init__()
        self.make_settings_data_fields(InputSettings)

    @property
    def min_upstream_nodes() -> int:
        return 0

    @property
    def type() -> str:
        return 'input'

    