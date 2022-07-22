import pytest
from python.directed_acyclic_graph import DirectedAcyclicGraph, Compile, DagNode
from python.layers.compilation.losses import CategoricalCrossentropy
from python.layers.compilation.optimizer import Adagrad
from python.layers.compilation.metrics import Accuracy
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
    return o


@pytest.fixture
def mnist():
    return keras_datasources[1]


@pytest.fixture
def map_range_image():
    m = MapRange()
    m.update_settings(
        dict(
            io=0,
            old_range_min="0",
            old_range_max="255",
            new_range_min="-1",
            new_range_max="1",
        )
    )
    return m


@pytest.fixture
def compile(dag: DirectedAcyclicGraph):
    c = Compile()
    c_node = dag.add_node(c)

    loss = CategoricalCrossentropy()
    loss_node = dag.add_node(loss)

    opt = Adagrad()
    opt_node = dag.add_node(opt)

    met = Accuracy()
    met_node = dag.add_node(met)

    c_node.layer.update_settings(
        dict(
            loss_node_id=loss_node.id.hex,
            optimizer_node_id=opt_node.id.hex,
            metric_node_ids=[met_node.id.hex],
        )
    )

    dag.connect_nodes(loss_node.id, c_node.id)
    dag.connect_nodes(opt_node.id, c_node.id)
    dag.connect_nodes(met_node.id, c_node.id)

    return c_node


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
    compile: DagNode,
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

    compile.layer.update_settings(dict(output_node_id=output_node.id.hex))
    dag.connect_nodes(output_node.id, compile.id)

    dag.fit_node.layer.update_settings(dict(epochs="10"))

    return dag
