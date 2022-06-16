from pydantic import ValidationError, validator, StrictInt
from python.directed_acyclic_graph import Layer, LayerSettings, DagNode, CompileException, CompileErrorReason
from python.layers.datasources_and_preprocessing.datasources import DatasetVars, KerasDatasource
from typing import Literal


class PreprocessingLayer(Layer):
    def __init__(self):
        super().__init__()
        self.datasource: KerasDatasource = None

    def get_datasource(self, node: DagNode):
        """
        Populates the self.datasource variable by accessing the upstream node
        which must be either a Preprocessing Layer or a Datasource.
        """
        if self.constructed:
            raise CompileException({
                'node_id': str(node.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': "This preprocessing node has already been constructed, you cannot construct a model twice."
            })
        upstream_layer = node.upstream_nodes[0].layer
        if isinstance(upstream_layer, PreprocessingLayer):
            self.datasource = upstream_layer.datasource
        elif isinstance(upstream_layer, KerasDatasource):
            self.datasource = upstream_layer
        else:
            raise CompileException({
                'node_id': str(node.id), 
                'reason': CompileErrorReason.INPUT_MISSING.camel(), 
                'errors': "This preprocessing layer requires either a datasource"
                " or another preprocessing layer as its incoming connection."
            })



class InputOrOutputSetting(LayerSettings):
    io: Literal[0, 1] # x or y


class MapRangeSettings(InputOrOutputSetting):
    old_range_min: float
    old_range_max: float
    new_range_min: float
    new_range_max: float

    @validator("new_range_max")
    def range_not_zero(cls, v, values):
        if v == values['new_range_min']:
            raise ValueError("Range must span distance greater than zero.")
        if values['old_range_max'] == values['old_range_min']:
            raise ValueError("Range must span distance greater than zero.")
        return v


class MapRange(PreprocessingLayer):
    settings_validator = MapRangeSettings
    type = "map_range"

    def generate_code_line(self, node_being_built: DagNode) -> str:
        self.get_datasource(node_being_built)

        try:
            ranges: MapRangeSettings = self.settings_validator(**self.settings_data)
            dataset: DatasetVars = self.datasource.dataset
            lines = "# Mapping old range to new range\n" + "\n".join(
                f"{dataset[i][ranges.io]} = ({dataset[i][ranges.io]} - {ranges.old_range_min}) / ({ranges.old_range_max} - {ranges.old_range_min}) "
                f"* ({ranges.new_range_max} - {ranges.new_range_min}) + {ranges.new_range_min}"
                for i in range(len(dataset))
            )
            self.constructed = True
            return lines
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.SETTINGS_VALIDATION.camel(), 
                'errors': e.errors()
            })


class OneHotSettings(LayerSettings):
    n_classes: StrictInt

    @validator('n_classes')
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
            lines += f"{self.datasource.dataset.train.y} = one_hot_encode({self.datasource.dataset.train.y})\n\n"

            self.constructed = True
            return lines
        except ValidationError as e:
            raise CompileException({
                'node_id': str(node_being_built.id), 
                'reason': CompileErrorReason.SETTINGS_VALIDATION.camel(), 
                'errors': e.errors()
            })

