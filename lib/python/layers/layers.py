from python.directed_acyclic_graph import Layer
# This file handles calls from dart to layers.
    

def create_layer(layer_cls_name: str) -> Layer:
    layer_cls = globals()[layer_cls_name]
    return layer_cls()