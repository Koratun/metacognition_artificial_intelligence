from python.directed_acyclic_graph import LayerSettings, Layer
from math import inf


class OutputSettings(LayerSettings):
    loss: str


class Output(Layer):
    settings_validator = OutputSettings

    @property
    def type() -> str:
        return 'model'

    @property
    def max_upstream_nodes() -> int:
        return inf