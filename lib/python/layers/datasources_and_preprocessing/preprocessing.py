from pydantic import ValidationError
from python.directed_acyclic_graph import Layer, LayerSettings, DagNode, CompileException, CompileErrorReason
from python.layers.datasources_and_preprocessing.datasources import DatasetVars, KerasDatasource
from typing import Literal


class PreprocessingLayer(Layer):
    def get_datasetvars(self, node: DagNode) -> DatasetVars:
        if self.constructed:
            raise CompileException({
                'node_id': str(node.id), 
                'reason': CompileErrorReason.COMPILATION_VALIDATION.camel(), 
                'errors': "This preprocessing node has already been constructed, you cannot construct a model twice."
            })
        upstream_layer = node.upstream_nodes[0].layer
        if upstream_layer in (PreprocessingLayer, KerasDatasource):
            return upstream_layer.dataset
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


class MapRange(PreprocessingLayer):
    settings_validator = MapRangeSettings


    def generate_code_line(self, node_being_built: DagNode) -> str:
        dataset = self.get_datasetvars(node_being_built)

        try:
            ranges: MapRangeSettings = self.settings_validator(**self.settings_data)
            lines = "\n".join(
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

