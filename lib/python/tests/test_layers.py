from python.layers import layer_classes
from python.layers.datasources_and_preprocessing.datasources import KerasDatasource
from python.directed_acyclic_graph import Layer, LayerSettings, NamedLayerSettings


def test_layers_implemented_properly():
    for layer_cls in layer_classes.values():
        if not isinstance(layer_cls, KerasDatasource):
            assert issubclass(layer_cls, Layer)
        assert not issubclass(layer_cls.settings_validator, NamedLayerSettings) or layer_cls.type != Layer.type
        assert layer_cls.settings_validator is not None
        assert issubclass(layer_cls.settings_validator, LayerSettings)


class TestUpdateLayer:
    """
    When new types of settings are created
    (i.e. the Type of a field is not present in the test below),
    then tests for that field type should be added here.
    Tests for every single layer are not necessary.
    Only every unique field type.
    """

    def test_units_name(self):
        layer = layer_classes["Dense"]()
        assert layer.update_settings({"units": ""})
        assert layer.update_settings({"units": "a"})
        assert not layer.update_settings({"units": "16"})
        assert layer.update_settings({"name": ""})
        assert layer.update_settings({"name": "9full_layer"})
        assert layer.update_settings({"name": "Full Layer"})
        assert layer.update_settings({"name": "Full_Layer"})
        assert layer.update_settings({"name": "full layer"})
        assert not layer.update_settings({"name": "fully_connected_layer"})

    def test_shape_dtype(self):
        layer = layer_classes["Input"]()
        assert layer.update_settings(dict(shape=""))
        assert layer.update_settings(dict(shape="("))
        assert layer.update_settings(dict(shape="(1)"))
        assert layer.update_settings(dict(shape="(1, 2.1)"))
        assert not layer.update_settings(dict(shape="(1,)"))
        assert not layer.update_settings(dict(shape="(1,16)"))
        assert not layer.update_settings(dict(shape="(1, None)"))
        assert not layer.update_settings(dict(dtype="float64"))

    def test_loss(self):
        layer = layer_classes["Output"]()
        assert not layer.update_settings(dict(loss="binary_cross_entropy"))

    def test_valtest_split(self):
        layer = layer_classes["CIFAR10"]()
        assert layer.update_settings(dict(validation_test_split="a"))
        assert layer.update_settings(dict(validation_test_split="-1"))
        assert layer.update_settings(dict(validation_test_split="2"))
        assert layer.update_settings(dict(validation_test_split="-0.1"))
        assert layer.update_settings(dict(validation_test_split="1.1"))
        assert not layer.update_settings(dict(validation_test_split="0"))
        assert not layer.update_settings(dict(validation_test_split="1"))
        assert not layer.update_settings(dict(validation_test_split=".3"))

    def test_io_range(self):
        layer = layer_classes["MapRange"]()
        assert not layer.update_settings(
            dict(
                io=1,
                old_range_min="0",
                old_range_max="10",
                new_range_min="0",
                new_range_max="1",
            )
        )
        assert layer.update_settings(dict(io="a"))
        assert layer.update_settings(dict(io=2))
        assert layer.update_settings(dict(io=0.5))
        assert not layer.update_settings(dict(io=0))
        assert layer.update_settings(dict(new_range_min="1"))
        assert not layer.update_settings(dict(new_range_min="-1"))
        assert layer.update_settings(dict(old_range_min="10"))
        assert not layer.update_settings(dict(old_range_min="-10"))

    def test_nclasses(self):
        layer = layer_classes["OneHotEncode"]()
        assert layer.update_settings(dict(n_classes="a"))
        assert layer.update_settings(dict(n_classes="0"))
        assert layer.update_settings(dict(n_classes="2"))
        assert layer.update_settings(dict(n_classes="3.5"))
        assert not layer.update_settings(dict(n_classes="10"))

    def test_logits(self):
        layer = layer_classes["BinaryCrossentropy"]()
        assert layer.update_settings(dict(from_logits="bee"))
        assert not layer.update_settings(dict(from_logits="False"))
        assert not layer.update_settings(dict(from_logits="True"))

    def test_learning_rate(self):
        layer = layer_classes["RMSPropSettings"]()
        assert layer.update_settings(dict(learning_rate="0.01"))
        assert layer.update_settings(dict(learning_rate="0.1"))
        assert not layer.update_settings(dict(learning_rate="0.001"))

    def test_rho(self):
        layer = layer_classes["RMSPropSettings"]()
        assert layer.update_settings(dict(rho="9"))
        assert layer.update_settings(dict(rho="0"))
        assert not layer.update_settings(dict(rho="0.9"))

    def test_momentum(self):
        layer = layer_classes["RMSPropSettings"]()
        assert layer.update_settings(dict(momentum="1"))
        assert layer.update_settings(dict(momentum="0.5"))
        assert not layer.update_settings(dict(momentum="0.0"))

    def test_centered(self):
        layer = layer_classes["RMSPropSettings"]()
        assert layer.update_settings(dict(centered="dog"))
        assert not layer.update_settings(dict(centered="True"))
        assert not layer.update_settings(dict(centered="False"))

    def test_initial_accumulator_value(self):
        layer = layer_classes["AdagradSettings"]()
        assert layer.update_settings(dict(initial_accumulator_value="-1"))
        assert not layer.update_settings(dict(initial_accumulator_value="0.1"))
        assert not layer.update_settings(dict(initial_accumulator_value="1"))

    def test_learning_rate_power(self):
        layer = layer_classes["FtrlSettings"]()
        assert layer.update_settings(dict(learning_rate_power="1"))
        assert not layer.update_settings(dict(learning_rate_power="-0.5"))
        assert not layer.update_settings(dict(learning_rate_power="-0.2"))

    def test_l2_shrinkage_regularization_strength(self):
        layer = layer_classes["FtrlSettings"]()
        assert layer.update_settings(dict(l2_shrinkage_regularization_strength="1"))
        assert not layer.update_settings(dict(l2_shrinkage_regularization_strength="0.0"))
