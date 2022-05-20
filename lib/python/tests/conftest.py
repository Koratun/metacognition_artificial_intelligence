import pytest
from python.directed_acyclic_graph import DirectedAcyclicGraph


@pytest.fixture
def dag() -> DirectedAcyclicGraph:
    """
    An empty dag for tests to use
    """
    return DirectedAcyclicGraph()


@pytest.fixture
def simple_dag(dag):
    pass
