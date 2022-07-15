from python.directed_acyclic_graph import Layer, Loss, Metric, NamedLayerSettings, Optimizer
from typing import Type
from pathlib import Path
from python.layers.datasources_and_preprocessing.datasources import keras_datasources
# When a new layer is created, add it to the list!
from python.layers import (
    input,
    dense, 
    output
)
from python.layers.compilation import(
    optimizer,
    metrics,
    losses
)
from python.layers.datasources_and_preprocessing import (
    preprocessing
)


layer_classes: dict[str, Type[Layer]] = {}
# Loop backwards through globals() until we hit 
# whatever the first non-layer-subclass is

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
            if isinstance(attr, type):
                if (attr is not Layer 
                and issubclass(attr, Layer)
                and attr not in (preprocessing.PreprocessingLayer,Loss,Metric,Optimizer) 
                and (attr.type != Layer.type or not issubclass(attr.settings_validator,NamedLayerSettings))):
                    layer_classes[attr_name] = attr
                    if package_list := layer_packages.get(mod_parent):
                        package_list.insert(0, attr_name)
                    else:
                        layer_packages[mod_parent] = [attr_name]

    if breakflag:
        break

layer_classes.update({c.label: c for c in keras_datasources})
layer_packages['datasources_and_preprocessing'] += [c.label for c in keras_datasources]
