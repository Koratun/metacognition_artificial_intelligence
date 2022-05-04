from enum import Enum
from uuid import UUID
from typing import Union, Optional, Type
from pydantic import BaseModel, validator
from python.directed_acyclic_graph import CompileErrorReason
from math import inf


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



class StartupResponse(BaseModel):
    category_list: dict[str, list[str]]


class NodeConnectionLimits(BaseModel):
    @validator('*', pre=True)
    def infinity_check(cls, v):
        if v is inf:
            return 'inf'
        return v

    min_upstream: Union[int, str]
    max_upstream: Union[int, str]
    min_downstream: Union[int, str]
    max_downstream: Union[int, str]


class CreationResponse(BaseModel):
    node_id: UUID
    layer_settings: list[str]
    node_connection_limits: NodeConnectionLimits


class SuccessFailResponse(BaseModel):
    error: Optional[str]


class CompileSuccessResponse(BaseModel):
    py_file: str


class ValidationError(BaseModel):
    loc: list[str]
    msg: str
    type: str


class ValidationErrorResponse(BaseModel):
    __root__: list[ValidationError]


class CompileErrorResponse(BaseModel):
    node_id: UUID
    reason: CompileErrorReason
    errors: str

    class Config:
        use_enum_values = True


class CompileErrorDisjointedResponse(BaseModel):
    node_ids: list[UUID]
    reason: CompileErrorReason
    errors: str

    class Config:
        use_enum_values = True


class CompileErrorSettingsValidationResponse(BaseModel):
    node_id: UUID
    reason: CompileErrorReason
    errors: ValidationErrorResponse

    class Config:
        use_enum_values = True


class GraphExceptionResponse(BaseModel):
    error: str
