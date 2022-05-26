from python.schemas import layer_classes
from python.directed_acyclic_graph import Layer, LayerSettings
from python.layers.dense import Dense
from python.layers.input import Input
from python.layers.output import Output
from pydantic import ValidationError


def test_layers_implemented_properly():
    for layer_cls in layer_classes.values():
        assert layer_cls.type != Layer.type
        assert issubclass(layer_cls, Layer)
        assert layer_cls.settings_validator not in (None, LayerSettings)
        assert issubclass(layer_cls.settings_validator, LayerSettings)


def test_update_layer():
    '''
    When new types of settings are created 
    (i.e. the Type of a field is not present in the test below), 
    then tests for that field type should be added here. 
    Tests for every single layer are not necessary.
    Only every unique field type.
    '''
    layer = Dense()
    assert layer.update_settings({'units': ''})
    assert layer.update_settings({'units': 'a'})
    assert not layer.update_settings({'units': '16'})

    layer = Input()
    assert layer.update_settings(dict(shape=''))
    assert layer.update_settings(dict(shape='('))
    assert layer.update_settings(dict(shape='(1)'))
    # assert layer.update_settings(dict(shape='(1, 2.1)'))
    assert not layer.update_settings(dict(shape='(1,)'))
    assert not layer.update_settings(dict(shape='(1,16)'))
    assert not layer.update_settings(dict(dtype='float64'))

    layer = Output()
    assert not layer.update_settings(dict(loss='binary_cross_entropy'))




        