from python.directed_acyclic_graph import Layer
# This file handles calls from dart to layers.
def snake_to_pascal_case(s: str) -> str:
    """
    Converts a snake_case string to PascalCase.
    Also capitalize the first letter directly after a number.
    """
    response = ''
    for i, c in enumerate(s):
        if c.isnumeric():
            if i > 0 and s[i-1].isnumeric():
                response += c.upper()
            else:
                response += c
        elif c.isalpha():
            response += c.upper()
        else:
            response += '_'
    

def create_layer(layer_cls_name: str) -> Layer:
    layer_cls = globals()[layer_cls_name]
    return layer_cls()