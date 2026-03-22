    .section .text.init
    .globl _start
_start:
    # 0. 设置 sp 为 _ekernel 之后 4 KiB 的位置
    la a0, _ekernel

    li t0, 0x1000
    add sp, a0, t0
    # 1. 跳转到 start_kernel
    j start_kernel

