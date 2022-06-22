from typing import Optional
from python.directed_acyclic_graph import LayerSettings, Metric, NamedLayerSettings
from python.layers.layers import Dtype

class AccuracySettings(LayerSettings):
    dtype: Optional[Dtype] = None
class PoissonSettings(LayerSettings):
    dtype: Optional[Dtype] = None
class LogCoshErrorSetings(LayerSettings):
    dtype: Optional[Dtype] = None
class Accuracy(Metric):
    settings_validator = AccuracySettings
class Poisson(Metric):
    settings_validator = PoissonSettings
class LogCoshError(Metric):
    settings_validator = LogCoshErrorSetings