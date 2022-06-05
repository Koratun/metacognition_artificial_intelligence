from enum import Enum
import abc


class FormatEnum(Enum):
    """
    This is a base class for all special settings formats.
    """
    @abc.abstractmethod
    def __str__(self):
        raise NotImplementedError()


class Dtype(FormatEnum):
    bfloat16 = 'bfloat16'       # 16-bit bfloat (brain floating point).
    bool = 'bool'               # Boolean.
    complex128 = 'complex128'   # 128-bit complex.
    complex64 = 'complex64'     # 64-bit complex.
    double = 'double'           # 64-bit (double precision) floating-point.
    float16 = 'float16'         # 16-bit (half precision) floating-point.
    float32 = 'float32'         # 32-bit (single precision) floating-point.
    float64 = 'float64'         # 64-bit (double precision) floating-point.
    half = 'half'               # 16-bit (half precision) floating-point.
    int16 = 'int16'             # Signed 16-bit integer.
    int32 = 'int32'             # Signed 32-bit integer.
    int64 = 'int64'             # Signed 64-bit integer.
    int8 = 'int8'               # Signed 8-bit integer.
    qint16 = 'qint16'           # Signed quantized 16-bit integer.
    qint32 = 'qint32'           # signed quantized 32-bit integer.
    qint8 = 'qint8'             # Signed quantized 8-bit integer.
    quint16 = 'quint16'         # Unsigned quantized 16-bit integer.
    quint8 = 'quint8'           # Unsigned quantized 8-bit integer.
    resource = 'resource'       # Handle to a mutable, dynamically allocated resource.
    string = 'string'           # Variable-length string, represented as byte array.
    uint16 = 'uint16'           # Unsigned 16-bit (word) integer.
    uint32 = 'uint32'           # Unsigned 32-bit (dword) integer.
    uint64 = 'uint64'           # Unsigned 64-bit (qword) integer.
    uint8 = 'uint8'             # Unsigned 8-bit (byte) integer.
    variant = 'variant'         # Data of arbitrary type (known at runtime).

    def __str__(self):
        return 'tf.' + self.value
