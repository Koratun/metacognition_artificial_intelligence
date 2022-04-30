from python.directed_acyclic_graph import LayerSettings, Layer


class DenseSettings(LayerSettings):
    units: int


class Dense(Layer):
    settings_validator = DenseSettings

    @property
    def type() -> str:
        return 'dense'