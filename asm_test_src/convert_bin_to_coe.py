import sys
import struct

source_name = sys.argv[1]
source_file = open(source_name, 'rb')

result_name = source_name[0: source_name.rindex('.')] + '.coe'
result_file = open(result_name,'wt')
result_file.write("memory_initialization_radix=16;\n")
result_file.write("memory_initialization_vector=\n")

for x in range(63):
    command = struct.unpack('I', source_file.read(4))
    result_file.write(f"{hex(command[0])},\n")
command = struct.unpack('I', source_file.read(4))
result_file.write(f"{hex(command[0])};\n")