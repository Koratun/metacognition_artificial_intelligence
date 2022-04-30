from typing import Optional
from python.layers.layers import Dtype
from python.directed_acyclic_graph import LayerSettings, Layer


class InputSettings(LayerSettings):
    shape: tuple[int, ...]
    dtype: Optional[Dtype] = None


class Input(Layer):
    settings_validator = InputSettings

    @property
    def min_upstream_nodes() -> int:
        return 0

    @property
    def type() -> str:
        return 'input'

    