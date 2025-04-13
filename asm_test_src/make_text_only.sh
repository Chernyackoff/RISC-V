#!/bin/bash
riscv64-unknown-elf-gcc -nostdlib -nostartfiles rv32i_test.S -Trv32i_test.ld -o rv32i_test.elf
riscv64-unknown-elf-objcopy -O binary --only-section=.text rv32i_test.elf rv32i_test.txt

hexdump -X rv32i_test.txt --length 0x100
