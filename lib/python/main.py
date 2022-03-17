import fileinput

print("Py Starting", flush=True)

for line in fileinput.input():
    if 'Exit' == line.rstrip():
        break
    print("Py says "+line.strip(), flush=True)

print("Ended", flush=True)
