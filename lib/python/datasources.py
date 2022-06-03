from python.directed_acyclic_graph import Layer, LayerSettings
from keras.datasets import (
    cifar10,          # image class
    cifar100,         # image class
    reuters,          # topic class
    imdb,             # sentiment class
    boston_housing,   # price regression
    mnist,            # image class
    fashion_mnist     # image class
)


class KerasDataSettings(LayerSettings):
    validation_test_split: float = 0.5


class KerasDatasource(Layer):
    settings_validator = KerasDataSettings

    def __init__(self, name):
        super().__init__()
        self.datasource_name = name

    
