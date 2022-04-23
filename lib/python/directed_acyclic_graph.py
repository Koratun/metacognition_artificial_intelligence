from uuid import uuid4
from layers.layer import Layer


class DagException(Exception):
    def __init__(self, *args: object):
        super().__init__(*args)


class DagNode:
    def __init__(self, layer: Layer):
        self.id = uuid4()
        self.layer = layer
        self.upstream_nodes: list[DagNode] = []
        self.downstream_nodes: list[DagNode] = []
        self.seen = False

    def code_gen(self) -> str:
        return self.layer.generate_code_line(self)

    def connect_to(self, node: 'DagNode'):
        self.add_downstream_node(node)
        node.add_upstream_node(self)

    def disconnect_from(self, node: 'DagNode'):
        self.remove_downstream_node(node)
        node.remove_upstream_node(self)

    def add_upstream_node(self, node: 'DagNode'):
        self.upstream_nodes.append(node)

    def add_downstream_node(self, node: 'DagNode'):
        self.downstream_nodes.append(node)

    def remove_upstream_node(self, node: 'DagNode'):
        self.upstream_nodes.remove(node)

    def remove_downstream_node(self, node: 'DagNode'):
        self.downstream_nodes.remove(node)


class DirectedAcyclicGraph:
    def __init__(self):
        self.nodes: list[DagNode] = []
        self.edges: list[tuple[DagNode, DagNode]] = []
        self.inputs: list[DagNode] = []


    def _unsee(self, construct = False):
        for n in self.nodes:
            n.seen = False
            if construct:
                n.layer.reset_construct()


    def get_head_nodes(self) -> list[DagNode]:
        for e in self.edges:
            e[1].seen = True
        head_nodes = [n for n in self.nodes if not n.seen]
        self._unsee()
        return head_nodes


    def _is_acyclic(self) -> bool:
        if len(self.edges) < 2:
            return True
        for head in self.get_head_nodes():
            head.seen = True
            if not self._is_acyclic(head):
                head.seen = False
                return False
            head.seen = False
        return True

    
    def _is_acyclic(self, node: DagNode) -> bool:
        for n in node.downstream_nodes:
            if n.seen:
                return False
            n.seen = True
            if not self._is_acyclic(n):
                n.seen = False
                return False
            n.seen = False
        return True


    def connect_nodes(self, source_node: DagNode, dest_node: DagNode):
        if (source_node, dest_node) in self.edges:
            raise DagException("Connection already exists")
        else:
            self.edges.append((source_node, dest_node))
            source_node.connect_to(dest_node)
            if not self._is_acyclic():
                self.edges.pop()
                source_node.disconnect_from(dest_node)
                raise DagException("Circular graphs not allowed")


    def disconnect_nodes(self, source_node: DagNode, dest_node: DagNode):
        if (source_node, dest_node) in self.edges:
            self.edges.remove((source_node, dest_node))
            source_node.disconnect_from(dest_node)


    def add_node(self, layer: Layer) -> DagNode:
        node = DagNode(layer)
        if not node in self.nodes:
            if layer.type == 'input':
                self.inputs.append(node)
            self.nodes.append(node)
            return node
        else:
            raise DagException("Node already added")


    def remove_node(self, node: DagNode):
        for e in list(self.edges):
            if node in e:
                self.edges.remove(e)
        self.nodes.remove(node)


    def construct_keras(self):
        if not self.edges:
            raise DagException("The graph has no connections")

        model_file = "##~ Model code generated by MAI: DO NOT TOUCH! ~Mai\n\n"

        for head in self.get_head_nodes():
            head.seen = True
            model_file += head.code_gen() + '\n'
            model_file += self._construct_keras(head)

        self._unsee(construct=True)
        return model_file


    def _construct_keras(self, node: DagNode):
        model_file = ''
        for n in node.downstream_nodes:
            upstream_loaded = True
            for upstream_node in n.upstream_nodes:
                if not upstream_node.seen:
                    upstream_loaded = False
            if upstream_loaded:
                n.seen = True
                model_file += n.code_gen() + '\n'
                model_file += self._construct_keras(n)

        return model_file + '\n'


