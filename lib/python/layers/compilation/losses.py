from python.directed_acyclic_graph import Loss, LayerSettings


class LogitsSetting(LayerSettings):
    from_logits: bool = False


class MeanSquaredError(Loss):
    settings_validator = LayerSettings


class BinaryCrossentropy(Loss):
    settings_validator = LogitsSetting


class CategoricalCrossentropy(Loss):
    settings_validator = LogitsSetting
