#!/bin/bash
if [ $# -eq 0 ]
then
    asm_source="rv32i_test.S"
    echo "asm file name is not provided. Use default source file: $asm_source"
else
    asm_source=$1
fi

#compile test prog from chossen test prog file
riscv64-linux-gnu-gcc -nostdlib -nostartfiles $asm_source -Tlinker_script.ld -o test_prog.elf
#get from elf file only text section 
riscv64-linux-gnu-objcopy -O binary --only-section=.text test_prog.elf test_prog_text_section.bin

python ./convert_bin_to_coe.py test_prog_text_section.bin

cp test_prog_text_section.coe ../src/

# Clean up intermediate binary file
rm test_prog.elf test_prog_text_section.bin test_prog_text_section.coe