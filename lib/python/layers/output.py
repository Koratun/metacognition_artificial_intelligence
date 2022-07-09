from python.directed_acyclic_graph import NamedLayerSettings, Layer, DagNode, CompileException, CompileErrorReason
from math import inf


class Output(Layer):
    settings_validator = NamedLayerSettings
    type = "model"
    keras_module_location = "keras"
    max_upstream_nodes = inf
    max_downstream_nodes = inf

    def valid_number_downstream_nodes(self, _: int) -> bool:
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
            return "[" + ", ".join([n.layer.name for n in input_nodes]) + "]"

    def _get_inputs_recurse(self, node: DagNode, output_seen: bool) -> list[DagNode]:
        input_nodes: list[DagNode] = []
        if not output_seen and node.layer.type == "input":
            return [node]
        else:
            if output_seen:
                if node.layer.type == "input":
                    output_seen = False
            elif node.layer.type == "model":
                output_seen = True
            for n in node.upstream_nodes:
                input_nodes += self._get_inputs_recurse(n, output_seen=output_seen)
            if not input_nodes:
                raise CompileException(
                    {
                        "node_id": str(node.id),
                        "reason": CompileErrorReason.INPUT_MISSING,
                        "errors": "This node has no input",
                    }
                )
        return input_nodes

    def generate_code_line(self, node_being_built: DagNode) -> str:
        line = self.name + " = keras.Model" + "(" + self._get_inputs(node_being_built) + ", "
        if len(node_being_built.upstream_nodes) > 1:
            line += "[" + ", ".join(n.layer.name for n in node_being_built.upstream_nodes) + "]"
        else:
            line += node_being_built.upstream_nodes[0].layer.name
        line += ")\n"
        self.constructed = True
        return line
