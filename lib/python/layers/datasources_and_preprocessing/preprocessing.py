from pydantic import ValidationError, validator, StrictInt
from python.directed_acyclic_graph import LayerSettings, DagNode, CompileException, CompileErrorReason, Layer
import python.layers.datasources_and_preprocessing.datasources as dt
from typing import Literal


class PreprocessingLayer(Layer):
    def __init__(self):
        super().__init__()
        self.datasource: dt.KerasDatasource = None

    def validate_connected_upstream(self, node: "DagNode"):
        if not isinstance(node.layer, PreprocessingLayer) and not isinstance(node.layer, dt.KerasDatasource):
            return "Only datasources and other preprocessing nodes can connect to a preprocessing node."

    def validate_connected_downstream(self, node: "DagNode"):
        if not isinstance(node.layer, PreprocessingLayer) and node.layer.__class__.__name__ != "Input":
            return "Preprocessing nodes must connect to other Preprocessing nodes or to an Input node."

    def get_datasource(self, node: DagNode):
        """
        Populates the self.datasource variable by accessing the upstream node
        which must be either a Preprocessing Layer or a Datasource.
        """
        if self.constructed:
            raise CompileException(
                {
                    "node_id": str(node.id),
                    "reason": CompileErrorReason.COMPILATION_VALIDATION,
                    "errors": "This preprocessing node has already been constructed, you cannot construct a model twice.",
                }
            )
        upstream_layer = node.upstream_nodes[0].layer
        if isinstance(upstream_layer, PreprocessingLayer):
            self.datasource = upstream_layer.datasource
        elif isinstance(upstream_layer, dt.KerasDatasource):
            self.datasource = upstream_layer
        else:
            raise CompileException(
                {
                    "node_id": str(node.id),
                    "reason": CompileErrorReason.INPUT_MISSING,
                    "errors": "This preprocessing layer requires either a datasource"
                    " or another preprocessing layer as its incoming connection.",
                }
            )


class InputOrOutputSetting(LayerSettings):
    io: Literal["0", "1"] = "0"  # x or y


class MapRangeSettings(InputOrOutputSetting):
    old_range_min: float
    old_range_max: float
    new_range_min: float
    new_range_max: float

    @validator("old_range_max")
    def old_range_not_zero(cls, v, values: dict):
        if v == values.get("old_range_min"):
            raise ValueError("Old range must span distance greater than zero.")
        return v

    @validator("new_range_max")
    def new_range_not_zero(cls, v, values: dict):
        if v == values.get("new_range_min"):
            raise ValueError("New range must span distance greater than zero.")
        return v


class MapRange(PreprocessingLayer):
    settings_validator = MapRangeSettings
    type = "map_range"

    def generate_code_line(self, node_being_built: DagNode) -> str:
        self.get_datasource(node_being_built)

        try:
            ranges: MapRangeSettings = self.settings_validator(**self.settings_data)
            dataset: dt.DatasetVars = self.datasource.dataset
            lines = "# Mapping old range to new range\n" + "\n".join(
                f"{dataset[i][int(ranges.io)]} = ({dataset[i][int(ranges.io)]} - {ranges.old_range_min}) / ({ranges.old_range_max} - {ranges.old_range_min}) "
                f"* ({ranges.new_range_max} - {ranges.new_range_min}) + {ranges.new_range_min}"
                for i in range(len(dataset))
            )
            self.constructed = True
            return lines + "\n"
        except ValidationError as e:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.SETTINGS_VALIDATION,
                    "errors": e.errors(),
                }
            )


class OneHotSettings(LayerSettings):
    n_classes: StrictInt

    @validator("n_classes")
    def classification_prob(cls, v):
        if v > 2:
            return v
        elif v == 2:
            raise ValueError("One Hot encoding not recommmended for Binary classification problem")
        else:
            raise ValueError("Invalid number")


class OneHotEncode(PreprocessingLayer):
    settings_validator = OneHotSettings
    type = "one_hot_encode"

    def generate_code_line(self, node_being_built: DagNode) -> str:
        self.get_datasource(node_being_built)

        try:
            n_classes: int = self.settings_validator(**self.settings_data).n_classes

            lines = "\n# One hot encoding the Y data\ndef one_hot_encode(y_data):\n"
            lines += f"\tencoded_y = np.zeros((len(y_data), {n_classes}))\n"
            lines += "\tfor i, y in enumerate(y_data):\n"
            lines += "\t\tencoded_y[i][y] = 1\n"
            lines += "\treturn encoded_y\n\n"
            lines += f"{self.datasource.dataset.train.y} = one_hot_encode({self.datasource.dataset.train.y})\n"
            lines += (
                f"{self.datasource.dataset.validation.y} = one_hot_encode({self.datasource.dataset.validation.y})\n\n"
            )

            self.constructed = True
            return lines
        except ValidationError as e:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.SETTINGS_VALIDATION,
                    "errors": e.errors(),
                }
            )


class NumpyFlatten(PreprocessingLayer):
    settings_validator = LayerSettings

    def generate_code_line(self, node_being_built: DagNode) -> str:
        self.get_datasource(node_being_built)
        dataset = self.datasource.dataset

        lines = "# Flattening numpy arrays\n"
        lines += "\n".join(
            f"{dataset[i].x} = {dataset[i].x}.reshape({dataset[i].x}.shape[0], -1)" for i in range(len(dataset))
        )
        return lines + "\n"
