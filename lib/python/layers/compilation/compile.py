from python.directed_acyclic_graph import LayerSettings, Layer


class CompileSettings(LayerSettings):
    __self__: LayerSettings


class Compile(Layer):
    settings_validator = CompileSettings
    type = 'compile'