from python.directed_acyclic_graph import Layer, LayerSettings
from python.directed_acyclic_graph import NamedLayerSettings, Optimizer, LayerSettings
from pydantic import validator


class RMSPropSettings(LayerSettings):
    learning_rate: float = (0.001,)
    rho: float = (0.9,)
    momentum: float = (0.0,)
    centered: bool = False


class AdagradSettings(LayerSettings):
    learning_rate: float = (0.001,)
    initial_accumulator_value: float = 0.1

    @validator("initial_accumulator_value")
    def postiveV(cls, v):
        if v >= 0:
            return v
        else:
            raise ValueError("The value must be greater than or equal to 0.")


class FtrlSettings(LayerSettings):
    learning_rate: float = (0.001,)
    # only less than or equal to 0 for learning rate power
    learning_rate_power: float = (-0.5,)

    @validator("learning_rate_power")
    def negativeV(cls, v):
        if v <= 0:
            return v
        else:
            raise ValueError("The value must be less than or equal to 0.")

    # only 0 or positive values for initial accumulator value
    initial_accumulator_value: float = (0.1,)

    @validator("initial_accumulator_value")
    def postiveV(cls, v):
        if v >= 0:
            return v
        else:
            raise ValueError("The value must be greater than or equal to 0.")

    # Magnitude penalty, only happen with active weights
    l2_shrinkage_regularization_strength: float = 0.0


class RMSProp(Optimizer):
    settings_validator = RMSPropSettings


class Adagrad(Optimizer):
    settings_validator = AdagradSettings


class Ftrl(Optimizer):
    settings_validator = FtrlSettings
