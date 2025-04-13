.globl _start
_start:
addi x1,x0, 1000
addi x2,x0, -300 
addi x3,x0, 1 
addi x4,x0, 2
addi x5,x0, -1
lui x6, 123 
add x7, x1, x2
sub x8, x1, x2
sra x9, x1, x3
srai x10, x1, 1
srl x11, x1, x4
srli x12, x1, 2
sll x13, x1, x3
slli x14, x1, 1
addi x15, x0, 0x555
sw x1,0x00(x0)
sw x2,0x04(x0)
sw x6,0x08(x0)
sw x9,0x0c(x0)
sw x10,0x10(x0)
sw x11,0x14(x0) 
sw x12,0x18(x0)
sw x13,0x1c(x0)
sw x14,0x20(x0)
and x16, x5, x15
andi x17, x5, 0x555
or x18, x0, x15
ori x19, x0, 0x555
xor x20, x0, x15
xori x21, x0, 0x555
sw x16,0x24(x0)
sw x17,0x28(x0) 
sw x18,0x2c(x0)
sw x19,0x30(x0)
sw x20,0x34(x0)
sw x21,0x38(x0)
slt x22, x1, x2
sltu x23, x1, x2
beq x1, x2, 0x8
addi x24,x0, 0x1
beq x1, x1, 0x8
addi x24,x0, 0x0
bne x1, x2, 0x8
addi x25, x0,0x1
bne x1, x1, 0x8
addi x25, x0,0x0
blt x1, x2, 0x8
addi x26, x0,0x1
blt x2, x1, 0x8
addi x26, x0,0x0
bltu x1, x2, 0x8
addi x27, x0,0x1
bltu x2, x1, 0x8
addi x27, x0,0x0
bge x1, x2, 0x8
addi x28, x0,0x1
bge x2, x1, 0x8
addi x28, x0,0x0
sw x22,0x3c(x0)
sw x23,0x40(x0)
sw x24,0x44(x0)
sw x25,0x48(x0)
sw x26,0x4c(x0)
sw x27,0x50(x0)

