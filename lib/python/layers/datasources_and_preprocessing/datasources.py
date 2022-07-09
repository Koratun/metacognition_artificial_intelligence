from python.directed_acyclic_graph import Layer, LayerSettings, DagNode, CompileException, CompileErrorReason
from python.layers.utils import Dtype
from pydantic import validator, ValidationError
from typing import NamedTuple


class KerasDataSettings(LayerSettings):
    validation_test_split: float = 0.5

    @validator("validation_test_split")
    def percent(cls, v):
        if 0 <= v and v <= 1:
            return v
        raise ValueError("Not a valid percentage")


class IO(NamedTuple):
    x: str
    y: str


class DatasetVars(NamedTuple):
    train: IO
    validation: IO
    test: IO


class KerasDatasource(Layer):
    settings_validator = KerasDataSettings
    min_upstream_nodes = 0
    max_upstream_nodes = 0
    max_downstream_nodes = 2

    def __init__(self, name: str, label: str, shape: tuple[int, ...], dtype: Dtype, classes: int):
        """
        Args:
            name: The name used by keras to load in these datasets.
            shape: The shape of the input data.
            dtype: The tf.dtype of the input data.
            classes: The number of classes the ouput can be, if this is a regression
                problem, then classes must be 0.
        """
        super().__init__()
        self.datasource_name: str = name
        self.label: str = label
        self.shape: tuple[int, ...] = shape
        self.dtype: Dtype = dtype
        self.classes: int = classes
        self.dataset = DatasetVars(
            *[IO(f"{name}_{dset}_x", f"{name}_{dset}_y") for dset in ["train", "validation", "test"]]
        )

    def __call__(self):
        return self

    def generate_code_line(self, node_being_built: DagNode) -> str:
        if self.constructed:
            raise CompileException(
                {
                    "node_id": str(node_being_built.id),
                    "reason": CompileErrorReason.COMPILATION_VALIDATION,
                    "errors": "This datasource node has already been constructed, you cannot construct a datasource twice.",
                }
            )
        try:
            split: float = self.settings_validator(**self.settings_data).validation_test_split

            # The following is a couple of helper functions to display progress to the user
            # and patching how Keras normally reports progress so that we can feed the progress
            # back to the user through whatever format we desire.
            # TODO: Update this when we know how the AI will be returning data to Flutter
            lines = (
                f"\nfrom keras.datasets import {self.datasource_name}\n\n# Loading in the {self.label} dataset"
                + """
def convert_bytes(num):
    for x in ['bytes', 'KB', 'MB', 'GB']:
        if num < 1024.0:
            return f"{num:.2f} {x}"
        num /= 1024.0


class PatchProgress:
    def __init__(self, total_size):
        self.total_size = total_size
        self.total_bytes = convert_bytes(self.total_size)

    def update(self, progress):
        # TODO: Update this when we know how the AI will be returning data to Flutter
        print(f"{convert_bytes(progress)}/{self.total_bytes}: {progress/self.total_size*100:.2f}%", 
            "Time till download is complete: {calculation goes here}")


from mock import patch
import keras.utils.data_utils

with patch(keras.utils.data_utils, 'Progbar', PatchProgress):"""
            )

            lines += f"\n\t({self.dataset.train.x}, {self.dataset.train.y}), ({self.dataset.test.x}, {self.dataset.test.y}) = {self.datasource_name}.load_data()\n\n"
            lines += f"{self.dataset.validation.x}, {self.dataset.test.x} = np.split({self.dataset.test.x}, int(len({self.dataset.test.x}) * {split}))\n"
            lines += f"{self.dataset.validation.y}, {self.dataset.test.y} = np.split({self.dataset.test.y}, int(len({self.dataset.test.y}) * {split}))\n\n"
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


# from keras.datasets import (
#     cifar10,          # image class
#     cifar100,         # image class
#     reuters,          # topic class
#     imdb,             # sentiment class
#     boston_housing,   # price regression
#     mnist,            # image class
#     fashion_mnist     # image class
# )

# cifar10.load_data()
# cifar100.load_data()
# # reuters.load_data()
# imdb.load_data()
# boston_housing.load_data()
# mnist.load_data()
# fashion_mnist.load_data()

keras_datasources = [
    KerasDatasource(name="boston_housing", label="Boston Housing", shape=(13,), dtype=Dtype.float32, classes=0),
    KerasDatasource(name="mnist", label="MNIST", shape=(28, 28), dtype=Dtype.int16, classes=10),
    KerasDatasource(name="fashion_mnist", label="Fashion MNIST", shape=(28, 28), dtype=Dtype.int16, classes=10),
    KerasDatasource(name="cifar10", label="CIFAR10", shape=(32, 32, 3), dtype=Dtype.int16, classes=10),
    KerasDatasource(name="cifar100", label="CIFAR100", shape=(32, 32, 3), dtype=Dtype.int16, classes=100),
    # KerasDatasource(name="reuters", label="Reuters", shape=(1, None), dtype=Dtype.int32, classes=90),
    # This dataset is too complex. Each document can have multiple classes which is out of scope for now.
    KerasDatasource(name="imdb", label="IMDB", shape=(1, None), dtype=Dtype.int32, classes=2),
]
