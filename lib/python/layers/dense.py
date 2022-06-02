from python.directed_acyclic_graph import NamedLayerSettings, Layer


class DenseSettings(NamedLayerSettings):
    units: int


class Dense(Layer):
    settings_validator = DenseSettings
    type = 'dense'
