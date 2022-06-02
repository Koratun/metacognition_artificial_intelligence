from uuid import UUID
from typing import Optional
from pydantic import ValidationError
from python.directed_acyclic_graph import LayerSettings, Layer, DagNode, CompileException, CompileErrorReason
from math import inf


class CompileSettings(LayerSettings):
    output_node_id: UUID
    loss_node_id: UUID
    optimizer_node_id: UUID
    metric_node_ids: Optional[list[UUID]]


class Compile(Layer):
    settings_validator = CompileSettings
    type = 'compile'
    min_upstream_nodes = 3
    max_upstream_nodes = inf
    max_downstream_nodes = inf

    def __init__(self):
        super().__init__()
        self.output: DagNode = None
        self.loss: DagNode = None
        self.optimizer: DagNode = None

    @property
    def name(self):
        # This should only ever be accessed when constructing the graph.
        # If it is accessed outside this context, there is a good chance
        # that python will spew out a NoneType access error
        return self.output.layer.name

    def generate_code_line(self, node_being_built: DagNode) -> str:
        if self.constructed:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': "This compile node has already been constructed, you cannot compile a model twice."
            })
        try:
            # Perform setting validation
            node_connections: CompileSettings = self.settings_validator(**self.settings_data)
            # We can assume that all the nodes are of the correct types and that
            # the three necessary nodes (out, loss, opt) are present since validation
            # has already passed. The Frontend will make sure that only nodes of the correct
            # type can be attached to the compile layer.
            metrics: list[DagNode] = []
            for n in node_being_built.upstream_nodes:
                n.seen = True
                if n.id == node_connections.output_node_id:
                    self.output = n
                elif n.id == node_connections.loss_node_id:
                    self.loss = n
                elif n.id == node_connections.optimizer_node_id:
                    self.optimizer = n
                elif n.id in node_connections.metric_node_ids:
                    metrics.append(n)

            line = f"{self.output.layer.name}.compile("
            line += f"\n\toptimizer={self.optimizer.code_gen()}, "
            line += f"\n\tloss={self.loss.code_gen()}, "
            line += f"\n\tmetrics=[{', '.join(n.code_gen() for n in metrics)}]\n)"
            self.constructed = True
            return line
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': e.errors()
            })
