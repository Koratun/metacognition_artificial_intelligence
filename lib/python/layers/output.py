from python.directed_acyclic_graph import LayerSettings, Layer, DagNode, CompileException, CompileErrorReason
from math import inf


class OutputSettings(LayerSettings):
    loss: str


class Output(Layer):
    settings_validator = OutputSettings

    @property
    def type() -> str:
        return 'model'

    @property
    def max_upstream_nodes() -> int:
        return inf

    @property
    def min_downstream_nodes() -> int:
        return 0

    @property
    def max_downstream_nodes() -> int:
        return inf

    def check_number_downstream_nodes(self, n: int) -> bool:
        # This will always be true because n is a positive number and
        # the limits being checked are positive numbers 0 <= n <= inf is always True
        return True 

    def _get_inputs(self, node_being_built: DagNode) -> str:
        input_nodes: list[DagNode] = []
        for n in node_being_built.upstream_nodes:
            input_nodes += self._get_inputs_recurse(n, output_seen=False)
        if len(input_nodes) == 1:
            return input_nodes[0].layer.name
        else:
            return '[' + ', '.join([n.layer.name for n in input_nodes]) + ']'


    def _get_inputs_recurse(self, node: DagNode, output_seen: bool) -> list[DagNode]:
        input_nodes: list[DagNode] = []
        if not output_seen and node.layer.type == 'input':
            return [node]
        else:
            if output_seen:
                if node.layer.type == 'input':
                    output_seen = False
            elif node.layer.type == 'model':
                output_seen = True
            for n in node.upstream_nodes:
                input_nodes += self._get_inputs_recurse(n, output_seen=output_seen)
            if not input_nodes:
                raise CompileException({
                    'node_id': str(node.id),
                    'reason': CompileErrorReason.INPUT_MISSING.value,
                    'errors': 'This node has no input'
                })
        return input_nodes


    def generate_code_line(self, node_being_built: DagNode) -> str:
        if len(node_being_built.upstream_nodes) < 1:
            raise CompileException({
                'node_id': str(node_being_built.id),
                'reason': CompileErrorReason.UPSTREAM_NODE_COUNT.value,
                'errors': 'Output layer must have at least one upstream node'
            })
        
        line = self.name + ' = keras.Model'+ '(' + self._get_inputs(node_being_built) + ', '
        if len(node_being_built.upstream_nodes) > 1:
            line += "[" + ', '.join(n.layer.name for n in node_being_built.upstream_nodes) + "]" 
        else:
            line += node_being_built.upstream_nodes[0].layer.name
        # TODO: IN PROGESS
        line += ')'
        self.constructed = True
        return line
