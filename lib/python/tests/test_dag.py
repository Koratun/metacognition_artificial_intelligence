from python.directed_acyclic_graph import DirectedAcyclicGraph, DagException
from python.layers.dense import Dense
from python.layers.input import Input
from python.layers.output import Output


class AssertException:
    def __init__(self, exception_type, exception_args):
        self.exception_type = exception_type
        self.exception_args = exception_args

    def __enter__(self):
        return self

    def __exit__(self, type, value: Exception, traceback):
        assert value
        assert value.__class__ == self.exception_type
        assert value.args[0] == self.exception_args
        return True


def test_add_remove_nodes(
        dag: DirectedAcyclicGraph, 
        basic_input: Input, 
        basic_dense: Dense,
        basic_output: Output
    ):
    input_node = dag.add_node(basic_input)
    dense_node = dag.add_node(basic_dense)
    output_node = dag.add_node(basic_output)

    assert dag.nodes == [input_node, dense_node, output_node]
    assert len(dag.edges) == 0

    with AssertException(DagException, "Connection not found"):
        dag.disconnect_nodes(input_node.id, dense_node.id)

    with AssertException(DagException, "Circular graphs not allowed"):
        dag.connect_nodes(input_node.id, input_node.id)

    dag.connect_nodes(input_node.id, dense_node.id)

    with AssertException(DagException, "Connection already exists"):
        dag.connect_nodes(input_node.id, dense_node.id)

    with AssertException(DagException, "Circular graphs not allowed"):
        dag.connect_nodes(dense_node.id, input_node.id)
    
    with AssertException(DagException, "Destination node has too many incoming connections"):
        dag.connect_nodes(output_node.id, dense_node.id)

    assert dense_node.downstream_nodes == []
    assert output_node.upstream_nodes == []

    dag.connect_nodes(dense_node.id, output_node.id)
    assert dense_node.downstream_nodes == [output_node]
    assert output_node.upstream_nodes == [dense_node]

    dag.disconnect_nodes(dense_node.id, output_node.id)
    assert dense_node.downstream_nodes == []
    assert output_node.upstream_nodes == []

    dag.connect_nodes(dense_node.id, output_node.id)

    with AssertException(DagException, "Source node has too many outgoing connections"):
        dag.connect_nodes(dense_node.id, input_node.id)

    with AssertException(DagException, "Circular graphs not allowed"):
        dag.connect_nodes(output_node.id, input_node.id)

    assert dag.edges == [(input_node, dense_node), (dense_node, output_node)]

    dag.remove_node(dense_node.id)

    assert dag.nodes == [input_node, output_node]
    assert dag.edges == []

    with AssertException(DagException, "Node not found"):
        dag.remove_node(dense_node.id)

    dag.remove_node(input_node.id)
    dag.remove_node(output_node.id)

    assert dag.nodes == []


def test_compile(simple_dag: DirectedAcyclicGraph):
    with open("MAI.py", 'w') as f:
        f.write(simple_dag.construct_keras())
