from typing import Optional
from python.layers.utils import Dtype
from python.directed_acyclic_graph import NamedLayerSettings, Layer
from pydantic import StrictInt


class InputSettings(NamedLayerSettings):
    shape: tuple[Optional[StrictInt], ...]
    dtype: Optional[Dtype] = None


class Input(Layer):
    settings_validator = InputSettings
    type = 'input'
