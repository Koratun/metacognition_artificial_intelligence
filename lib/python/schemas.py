from enum import Enum
from uuid import UUID
from typing import Optional, Type, Any
from pydantic import BaseModel, validator
from python.directed_acyclic_graph import CompileErrorReason, Layer
from humps import camelize
from pathlib import Path

# When a new layer is created, add it to the list!
from python.layers import (
    input,
    dense, 
    output
)


class CamelModel(BaseModel):
    class Config:
        alias_generator = camelize


layer_classes: dict[str, Type[Layer]] = {}
# Loop backwards through globals() until we hit 'Layer' 
# or whatever the first non-layer-subclass is

layer_packages: dict[str, list[str]] = {}

# We must wrap the globals call in a new dict because the very act
# of creating this loop will alter the global variables and 
# loops are not be able to iterate over changed iterators
for glob_mod_name, glob_mod in reversed(dict(globals()).items()):
    breakflag = False
    if glob_mod_name == 'input':
        breakflag = True
    if isinstance(glob_mod, type(input)):
        mod_parent = Path(glob_mod.__file__).parent.name
        if mod_parent == 'layers':
            mod_parent = 'core'
        # This is a module!
        # Iterate through the module to find an attribute of type Layer
        for attr_name, attr in reversed(glob_mod.__dict__.items()):
            if isinstance(attr, type(Layer)):
                layer_classes[attr_name] = attr
                if package_list := layer_packages.get(mod_parent):
                    package_list.insert(0, attr_name)
                else:
                    layer_packages[mod_parent] = [attr_name]
                break

    if breakflag:
        break


# Note that __root__ is not allowed to be used in these schemas;
# dart conversion will fail if it is used.
# Dart also cannot convert Union types.
# Any is also not an allowed type (except in the MetaSchema).
# Type is also not allowed.


class Command(Enum):
    STARTUP = 'startup'
    CREATE = 'create'
    UPDATE = 'update'
    DELETE = 'delete'
    CONNECT = 'connect'
    DISCONNECT = 'disconnect'
    COMPILE = 'compile'


class CreateLayer(BaseModel):
    layer: str

    @validator('layer', pre=True)
    def is_valid_layer(cls, v):
        if layer_classes.get(v):
            return v
        raise ValueError("Layer type not found")


class MetaSchema(BaseModel):
    title: str
    type: str
    properties: dict[str, dict[str, Any]]
    required: Optional[list[str]]
    definitions: Optional[dict[str, dict[str, Any]]]


class UpdateLayer(CreateLayer):
    id: UUID
    settings: dict[str, str]

    @validator('settings', pre=True)
    def setting_fields_match(cls, v: dict, values: dict, **kwargs):
        layer: Type[Layer] = layer_classes.get(values.get('layer'))
        if not layer:
            raise ValueError("Layer not provided")
        setting_schema = MetaSchema.parse_obj(layer.settings_validator.schema())
        all_fields = list(setting_schema.properties.keys())
        for given_field in v.keys():
            if given_field not in all_fields:
                raise ValueError(f"{given_field} is not a valid setting field for: {layer.__name__}")
        return v


class DeleteNode(BaseModel):
    id: UUID


class Connection(CamelModel):
    source_id: UUID
    dest_id: UUID


class ResponseType(Enum):
    STARTUP = "startup"
    SUCCESS_FAIL = "success_fail"
    CREATION = "creation"
    VALIDATION_ERROR = "validation_error"
    GRAPH_EXCEPTION = "graph_exception"
    COMPILE_ERROR = "compile_error"
    COMPILE_ERROR_DISJOINTED = "compile_error_disjointed"
    COMPILE_ERROR_SETTINGS_VALIDATION = "compile_error_settings_validation"
    COMPILE_SUCCESS = "compile_success"

    def get_model(self) -> Type[BaseModel]:
        if self == self.STARTUP:
            return StartupResponse
        elif self == self.SUCCESS_FAIL:
            return SuccessFailResponse
        elif self == self.CREATION:
            return CreationResponse
        elif self == self.VALIDATION_ERROR:
            return ValidationErrorResponse
        elif self == self.GRAPH_EXCEPTION:
            return GraphExceptionResponse
        elif self == self.COMPILE_ERROR:
            return CompileErrorResponse
        elif self == self.COMPILE_ERROR_DISJOINTED:
            return CompileErrorDisjointedResponse
        elif self == self.COMPILE_ERROR_SETTINGS_VALIDATION:
            return CompileErrorSettingsValidationResponse
        elif self == self.COMPILE_SUCCESS:
            return CompileSuccessResponse

    def camel(self) -> str:
        return camelize(self.value)


class StartupResponse(CamelModel):
    category_list: dict[str, list[str]]


class NodeConnectionLimits(CamelModel):
    # These must be strings because pydantic can convert int to str
    # But dart cannot store a Union type where pydantic can,
    # Dart will have to check if the value is an int or a str
    min_upstream: str
    max_upstream: str
    min_downstream: str
    max_downstream: str


class CreationResponse(CamelModel):
    node_id: UUID
    layer_settings: list[str]
    node_connection_limits: NodeConnectionLimits


class SuccessFailResponse(BaseModel):
    error: Optional[str]


class CompileSuccessResponse(CamelModel):
    py_file: str


class ValidationError(BaseModel):
    loc: list[str]
    msg: str
    type: str


class ValidationErrorResponse(CamelModel):
    errors: list[ValidationError]


class CompileErrorResponse(CamelModel):
    node_id: UUID
    reason: CompileErrorReason
    errors: str

    class Config:
        use_enum_values = True


class CompileErrorDisjointedResponse(CamelModel):
    node_ids: list[UUID]
    reason: CompileErrorReason
    errors: str

    class Config:
        use_enum_values = True


class CompileErrorSettingsValidationResponse(ValidationErrorResponse):
    node_id: UUID
    reason: CompileErrorReason

    class Config:
        use_enum_values = True


class GraphExceptionResponse(BaseModel):
    error: str
