#!/bin/bash

riscv64-unknown-elf-gcc -nostdlib -nostartfiles rv32i_test.S -Trv32i_test.ld -o rv32i_test.elf
riscv64-unknown-elf-objcopy -O binary --only-section=.text rv32i_test.elf rv32i_test.bin

# Convert binary to Verilog hex format
# -p: plain hex dump
# -c 4: group by 4 bytes (32 bits)
# sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/': Reverse byte order within each 32-bit word
#                                             (Needed because objcopy outputs little-endian bytes,
#                                              and $readmemh expects the word value, often interpreted MSB first)
# Adjust sed if your core/memory expects big-endian words directly.
xxd -p -c 4 rv32i_test.bin | sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > rv32i_test_memh.hex

echo "Generated rv32i_test_memh.hex (first 256 bytes):"
head -n 64 rv32i_test_memh.hex

# Clean up intermediate binary file
rm rv32i_test.bin