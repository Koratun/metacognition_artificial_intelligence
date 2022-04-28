import fileinput
import json
from python.directed_acyclic_graph import DirectedAcyclicGraph

dag = DirectedAcyclicGraph()


def write_back(s: str):
    print(s, flush=True)


def main():

    write_back("Py Starting")

    for line in fileinput.input():
        if 'Exit' == line.rstrip():
            break
        write_back("Py says "+line.strip())

    write_back("Ended")


def jsonify(s: str):
    """
    Endpoint must be called with the following format:
    {
        "command": "create_input"
        "payload": {

        }
    }
    """
    request = json.loads(s)
    command: str = request['command']
    if command[:command.find('_')] == 'create':
        pass
    


if __name__ == '__main__':
    main()