import abc
from pydantic import BaseModel, ValidationError
from python.directed_acyclic_graph import Layer, DagNode


class InputSettings(BaseModel):
    shape: list[int]
    # dtype: Optional[Dtype]


class Input(Layer, metaclass=abc.ABCMeta):
    def __init__(self):
        super().__init__()
        self.make_settings_data_fields(InputSettings)

    @property
    def min_upstream_nodes() -> int:
        return 0

    @property
    def type() -> str:
        return 'input'

    def validate_syntax(self, node_being_built: DagNode):
        errors = {}
        errors['setting_errors'] = self.validate_settings()
        errors['node_errors'] = []
        if not self.check_number_upstream_nodes(len(node_being_built.upstream_nodes)):
            errors['node_errors'].append('upstream count out of bounds')
        if not self.check_number_downstream_nodes(len(node_being_built.downstream_nodes)):
            errors['node_errors'].append('downstream count out of bounds')
        return {k: v for k, v in errors.items() if v}


if __name__ == "__main__":
    def test(cls, **data):
        try:
            cls(**data)
        except ValidationError as e:
            print(e.errors())
            print(e.raw_errors)

    test(InputSettings, shape='')
    