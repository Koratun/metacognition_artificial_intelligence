from pydantic import BaseModel, ValidationError
from python.directed_acyclic_graph import Layer, DagNode


class InputSettings(BaseModel):
    shape: list[int]


class Input(Layer):
    def __init__(self):
        super().__init__()
        self.make_settings_data_fields(InputSettings)
        

    @property
    def type() -> str:
        return 'input'

    # def validate_syntax(self, node_being_built: DagNode):
        


if __name__ == "__main__":
    def test(cls, **data):
        try:
            cls(**data)
        except ValidationError as e:
            print(e.errors())
            print(e.raw_errors)

    test(InputSettings, shape='')
    