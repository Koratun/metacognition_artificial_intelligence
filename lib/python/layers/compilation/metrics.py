from typing import Optional
from python.directed_acyclic_graph import LayerSettings, Metric, NamedLayerSettings
from python.layers.utils import Dtype

class MetricsSettings(LayerSettings):
    dtype: Optional[Dtype] = None
class Accuracy(Metric):
    settings_validator = MetricsSettings
class Poisson(Metric):
    settings_validator = MetricsSettings
class LogCoshError(Metric):
    settings_validator = MetricsSettings