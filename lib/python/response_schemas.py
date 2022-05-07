from enum import Enum
from uuid import UUID
from typing import Optional, Type
from pydantic import BaseModel
from python.directed_acyclic_graph import CompileErrorReason

# Note that __root__ is not allowed to be used in these schemas
# dart conversion will fail if it is used
# Dart also cannot convert Union types


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
        s = self.value
        camel_string = ''
        for i, c in enumerate(s):
            if i == 0:
                camel_string += c
            elif c == '_':
                camel_string += s[i + 1].upper()
            elif s[i - 1] == '_':
                continue
            else:
                camel_string += c
        return camel_string


class StartupResponse(BaseModel):
    category_list: dict[str, list[str]]


class NodeConnectionLimits(BaseModel):
    # These must be strings because pydantic can convert int to str
    # But dart cannot store a Union type where pydantic can,
    # Dart will have to check if the value is an int or a str
    min_upstream: str
    max_upstream: str
    min_downstream: str
    max_downstream: str


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
    errors: list[ValidationError]


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


class CompileErrorSettingsValidationResponse(ValidationErrorResponse):
    node_id: UUID
    reason: CompileErrorReason

    class Config:
        use_enum_values = True


class GraphExceptionResponse(BaseModel):
    error: str
