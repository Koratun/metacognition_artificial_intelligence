from pydantic import ValidationError
from python.directed_acyclic_graph import (
    DagException,
    LayerSettings,
    Layer,
    DagNode,
    CompileException,
    CompileErrorReason,
    Compile,
)
from python.layers.datasources_and_preprocessing.datasources import KerasDatasource


class FitSettings(LayerSettings):
    batch_size: int = 32
    epochs: int
    shuffle: bool = True


class Fit(Layer):
    settings_validator = FitSettings
    min_downstream_nodes = 0
    max_downstream_nodes = 0

    def _find_datasource(self, node: DagNode) -> KerasDatasource:
        if isinstance(node.layer, KerasDatasource):
            return node.layer
        elif isinstance(node.layer, Compile):
            return self._find_datasource(node.layer.output)
        else:
            if len(node.upstream_nodes) == 0:
                raise DagException("No datasource found")
            return self._find_datasource(node.upstream_nodes[0])

    def generate_code_line(self, node_being_built: DagNode) -> str:
        datasource = self._find_datasource(node_being_built)
        try:
            compile: Compile = node_being_built.upstream_nodes[0].layer

            line = f"\nhistory = {compile.output.layer.name}.fit(x={datasource.dataset.train.x}, y={datasource.dataset.train.y}, "
            line += f"validation_data=({datasource.dataset.validation.x}, {datasource.dataset.validation.y}), {self.construct_settings()})"
            return line
        except ValidationError as e:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.SETTINGS_VALIDATION,
                    "errors": e.errors(),
                }
            )
