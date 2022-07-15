import pytest
from python.directed_acyclic_graph import DirectedAcyclicGraph
from python.layers.dense import Dense
from python.layers.input import Input
from python.layers.output import Output
from python.layers.datasources_and_preprocessing.preprocessing import MapRange, OneHotEncode
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
    d.update_settings(dict(units="16"))
    return d


@pytest.fixture
def basic_input():
    inp = Input()
    inp.update_settings(dict(shape="(16,)"))
    return inp


@pytest.fixture
def basic_output():
    o = Output()
    o.update_settings(dict(loss="mse"))
    return o


@pytest.fixture
def mnist():
    return keras_datasources[1]


@pytest.fixture
def map_range_image():
    m = MapRange()
    m.update_settings(dict(io=0, old_range_min="0", old_range_max="255", new_range_min="-1", new_range_max="1"))
    return m


@pytest.fixture
def one_hot_mnist():
    h = OneHotEncode()
    h.update_settings(dict(n_classes="10"))
    return h


@pytest.fixture
def simple_dag(
    dag: DirectedAcyclicGraph, basic_dense, basic_input, basic_output, mnist, map_range_image, one_hot_mnist
):
    data_node = dag.add_node(mnist)
    map_node = dag.add_node(map_range_image)
    hot_node = dag.add_node(one_hot_mnist)

    input_node = dag.add_node(basic_input)
    dense_node = dag.add_node(basic_dense)
    output_node = dag.add_node(basic_output)

    dag.connect_nodes(data_node.id, map_node.id)
    dag.connect_nodes(data_node.id, hot_node.id)
    dag.connect_nodes(map_node.id, input_node.id)
    dag.connect_nodes(hot_node.id, input_node.id)

    dag.connect_nodes(input_node.id, dense_node.id)
    dag.connect_nodes(dense_node.id, output_node.id)
    return dag
