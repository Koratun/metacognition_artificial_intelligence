import pytest
from python.directed_acyclic_graph import DirectedAcyclicGraph
from python.layers.dense import Dense
from python.layers.input import Input
from python.layers.output import Output


@pytest.fixture
def dag() -> DirectedAcyclicGraph:
    """
    An empty dag for tests to use
    """
    return DirectedAcyclicGraph()


@pytest.fixture
def basic_dense():
    d = Dense()
    d.update_settings(dict(units='16'))
    return d


@pytest.fixture
def basic_input():
    inp = Input()
    inp.update_settings(dict(shape='(16,)'))
    return inp


@pytest.fixture
def basic_output():
    o = Output()
    o.update_settings(dict(loss="mse"))
    return o


@pytest.fixture
def simple_dag(dag, basic_dense, basic_input, basic_output):
    input_node = dag.add_node(basic_input)
    dense_node = dag.add_node(basic_dense)
    output_node = dag.add_node(basic_output)

    dag.connect_nodes(input_node.id, dense_node.id)
    dag.connect_nodes(dense_node.id, output_node.id)
    return dag
