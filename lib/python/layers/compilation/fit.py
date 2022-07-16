from pydantic import ValidationError
from python.directed_acyclic_graph import LayerSettings, Layer, DagNode, CompileException, CompileErrorReason


class FitSettings(LayerSettings):
    batch_size: int = 32
    epochs: int
    shuffle: bool = True


class Fit(Layer):
    settings_validator = FitSettings
    min_downstream_nodes = 0
    max_downstream_nodes = 0

    def generate_code_line(self, node_being_built: DagNode) -> str:
        try:
            line = "history = model.fit(" + "xdata, ydata, " + self.construct_settings() + ")"
            return line
        except ValidationError as e:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.SETTINGS_VALIDATION.camel(),
                    "errors": e.errors(),
                }
            )
