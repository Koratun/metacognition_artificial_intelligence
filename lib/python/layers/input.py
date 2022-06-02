from typing import Optional
from python.layers.layers import Dtype
from python.directed_acyclic_graph import NamedLayerSettings, Layer
from pydantic import StrictInt


class InputSettings(NamedLayerSettings):
    shape: tuple[StrictInt, ...]
    dtype: Optional[Dtype] = None


class Input(Layer):
    settings_validator = InputSettings
    type = 'input'
    keras_module_location = 'keras'
    min_upstream_nodes = 0
