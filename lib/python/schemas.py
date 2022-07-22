from enum import Enum
from uuid import UUID
from typing import Optional, Type, Any
from pydantic import BaseModel, validator
from python.directed_acyclic_graph import CompileErrorReason
from python.layers.utils import Dtype  # Dtype is needed here for dart schema creation!
from humps import camelize
from python.layers import layer_classes


# Note that __root__ is not allowed to be used in these schemas;
# dart conversion will fail if it is used.
# Dart also cannot convert Union types.
# Any is also not an allowed type (except in the MetaSchema).
# Type is also not allowed.


class CamelModel(BaseModel):
    class Config:
        alias_generator = camelize


class RequestResponseModel(CamelModel):
    request_id: UUID


class MetaSchema(BaseModel):
    title: str
    type: str
    properties: dict[str, dict[str, Any]]
    required: Optional[list[str]]
    definitions: Optional[dict[str, dict[str, Any]]]


class SchemaEnum(Enum):
    @classmethod
    @property
    def model_rep(cls) -> dict["SchemaEnum", Type[BaseModel]]:
        raise NotImplementedError()

    def get_model(self) -> Type[BaseModel]:
        return self.model_rep[self]

    def camel(self) -> str:
        return camelize(self.value)


### Begin CommandType Section ###


# NOTE: Commands will come from the frontend in camelCase
class CommandType(SchemaEnum):
    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"
    CONNECT = "connect"
    DISCONNECT = "disconnect"
    COMPILE = "compile"

    @classmethod
    @property
    def model_rep(cls) -> dict["SchemaEnum", Type[BaseModel]]:
        return command_model_rep


class CreateLayer(RequestResponseModel):
    layer: str

    @validator("layer", pre=True)
    def is_valid_layer(cls, v):
        if layer_classes.get(v):
            return v
        raise ValueError("Layer type not found")


class UpdateLayer(RequestResponseModel):
    id: UUID
    settings: dict[str, str]


class DeleteNode(RequestResponseModel):
    node_id: UUID


class Connection(RequestResponseModel):
    source_id: UUID
    dest_id: UUID


command_model_rep = {
    CommandType.CREATE: CreateLayer,
    CommandType.UPDATE: UpdateLayer,
    CommandType.DELETE: DeleteNode,
    CommandType.CONNECT: Connection,
    CommandType.DISCONNECT: Connection,
    CommandType.COMPILE: RequestResponseModel,
}


### End CommandType Section ###

### Begin EventType Section ###


class EventType(SchemaEnum):
    INITIALIZE_LAYERS = "initialize_layers"
    INIT_FIT = "init_fit"

    @classmethod
    @property
    def model_rep(self) -> dict["EventType", Type[BaseModel]]:
        return event_model_rep


class InitializeLayersEvent(CamelModel):
    category_list: dict[str, list[str]]


class InitFitEvent(CamelModel):
    # fitted: bool  # When we add saving we'll use this field
    node_id: UUID
    settings: dict[str, str]


event_model_rep = {
    EventType.INITIALIZE_LAYERS: InitializeLayersEvent,
    EventType.INIT_FIT: InitFitEvent,
}


### End EventType Section ###

### Begin ResponseType Section ###


class ResponseType(SchemaEnum):
    SUCCESS_FAIL = "success_fail"
    CREATION = "creation"
    VALIDATION = "validation"
    GRAPH_EXCEPTION = "graph_exception"
    COMPILE_ERROR = "compile_error"
    COMPILE_ERROR_DISJOINTED = "compile_error_disjointed"
    COMPILE_ERROR_SETTINGS_VALIDATION = "compile_error_settings_validation"
    COMPILE_SUCCESS = "compile_success"

    @classmethod
    @property
    def model_rep(cls) -> dict["ResponseType", Type[BaseModel]]:
        return response_model_rep


class NodeConnectionLimits(CamelModel):
    # These must be strings because pydantic can convert int to str
    # But dart cannot store a Union type where pydantic can,
    # Dart will have to check if the value is an int or a str
    min_upstream: int
    max_upstream: str
    min_downstream: int
    max_downstream: str


class CreationResponse(RequestResponseModel):
    node_id: UUID
    layer_settings: dict[str, str]
    node_connection_limits: NodeConnectionLimits


class SuccessFailResponse(RequestResponseModel):
    error: Optional[str]


class CompileSuccessResponse(RequestResponseModel):
    py_file: str


class ValidationError(BaseModel):
    loc: list[str]
    msg: str
    type: str


class ValidationResponse(RequestResponseModel):
    errors: Optional[list[ValidationError]]


class CompileErrorResponse(RequestResponseModel):
    node_id: UUID
    reason: CompileErrorReason
    errors: str

    class Config:
        use_enum_values = True


class CompileErrorDisjointedResponse(RequestResponseModel):
    node_ids: list[UUID]
    reason: CompileErrorReason
    errors: str

    class Config:
        use_enum_values = True


class CompileErrorSettingsValidationResponse(RequestResponseModel):
    errors: list[ValidationError]
    node_id: UUID
    reason: CompileErrorReason

    class Config:
        use_enum_values = True


class GraphExceptionResponse(RequestResponseModel):
    error: str


response_model_rep = {
    ResponseType.SUCCESS_FAIL: SuccessFailResponse,
    ResponseType.CREATION: CreationResponse,
    ResponseType.VALIDATION: ValidationResponse,
    ResponseType.GRAPH_EXCEPTION: GraphExceptionResponse,
    ResponseType.COMPILE_ERROR: CompileErrorResponse,
    ResponseType.COMPILE_ERROR_DISJOINTED: CompileErrorDisjointedResponse,
    ResponseType.COMPILE_ERROR_SETTINGS_VALIDATION: CompileErrorSettingsValidationResponse,
    ResponseType.COMPILE_SUCCESS: CompileSuccessResponse,
}


### End ResponseType Section ###
