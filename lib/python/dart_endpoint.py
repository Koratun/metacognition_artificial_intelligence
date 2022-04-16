import fileinput


def write_back(s: str):
    print(s, flush=True)


write_back("Py Starting")

for line in fileinput.input():
    if 'Exit' == line.rstrip():
        break
    write_back("Py says "+line.strip())

write_back("Ended")
