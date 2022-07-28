from typing import Optional
from python.directed_acyclic_graph import NamedLayerSettings, Layer
from python.layers.utils import Activation


class DenseSettings(NamedLayerSettings):
    units: int
    activation: Optional[Activation]


class Dense(Layer):
    settings_validator = DenseSettings
    type = "dense"
