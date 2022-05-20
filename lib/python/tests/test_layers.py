from python.schemas import layer_classes
from python.directed_acyclic_graph import Layer, LayerSettings


def test_layers_implemented_properly():
    for layer in layer_classes.values():
        assert layer.type != Layer.type
        assert issubclass(layer, Layer)
        assert layer.settings_validator not in (None, LayerSettings)
        assert issubclass(layer.settings_validator, LayerSettings)



