import pytest
from python.directed_acyclic_graph import DirectedAcyclicGraph, Compile, DagNode
from python.layers.compilation.losses import CategoricalCrossentropy
from python.layers.compilation.optimizer import Adagrad
from python.layers.compilation.metrics import CategoricalAccuracy
from python.layers.dense import Dense
from python.layers.input import Input
from python.layers.output import Output
from python.layers.datasources_and_preprocessing.preprocessing import MapRange, OneHotEncode, NumpyFlatten
from python.layers.datasources_and_preprocessing.datasources import keras_datasources


@pytest.fixture
def dag() -> DirectedAcyclicGraph:
    """
    An empty dag for tests to use
    """
    return DirectedAcyclicGraph()


@pytest.fixture
def basic_dense():
    d = Dense()
    d.update_settings(dict(units="64", activation="softmax"))
    return d


@pytest.fixture
def basic_input():
    inp = Input()
    inp.update_settings(dict(shape="(28*28,)"))
    return inp


@pytest.fixture
def basic_output():
    return Output()


@pytest.fixture
def mnist():
    return keras_datasources[1]


@pytest.fixture
def numpy_flatten():
    return NumpyFlatten()


@pytest.fixture
def map_range_image():
    m = MapRange()
    m.update_settings(
        dict(
            io="0",
            old_range_min="0",
            old_range_max="255",
            new_range_min="-1",
            new_range_max="1",
        )
    )
    return m


@pytest.fixture
def one_hot_mnist():
    h = OneHotEncode()
    h.update_settings(dict(n_classes="10"))
    return h


@pytest.fixture
def simple_dag(
    dag: DirectedAcyclicGraph,
    basic_dense,
    basic_input,
    basic_output,
    mnist,
    map_range_image,
    one_hot_mnist,
    numpy_flatten,
):
    data_node = dag.add_node(mnist)
    map_node = dag.add_node(map_range_image)
    hot_node = dag.add_node(one_hot_mnist)
    flat_node = dag.add_node(numpy_flatten)

    input_node = dag.add_node(basic_input)
    dense_node = dag.add_node(basic_dense)
    output_node = dag.add_node(basic_output)

    dag.connect_nodes(data_node.id, flat_node.id)
    dag.connect_nodes(flat_node.id, map_node.id)
    dag.connect_nodes(data_node.id, hot_node.id)
    dag.connect_nodes(map_node.id, input_node.id)
    dag.connect_nodes(hot_node.id, input_node.id)

    dag.connect_nodes(input_node.id, dense_node.id)
    dag.connect_nodes(dense_node.id, output_node.id)

    c = Compile()
    compile = dag.add_node(c)

    loss = CategoricalCrossentropy()
    loss_node = dag.add_node(loss)

    opt = Adagrad()
    opt_node = dag.add_node(opt)

    met = CategoricalAccuracy()
    met_node = dag.add_node(met)

    dag.connect_nodes(output_node.id, compile.id)

    dag.connect_nodes(met_node.id, compile.id)
    dag.connect_nodes(loss_node.id, compile.id)
    dag.connect_nodes(opt_node.id, compile.id)

    dag.fit_node.layer.update_settings(dict(epochs="10"))

    return dag
