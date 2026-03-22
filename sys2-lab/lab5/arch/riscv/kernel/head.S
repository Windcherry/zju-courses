#include "private_kdefs.h"

    .section .text.init
    .globl _start
_start:
    # 0. 设置 sp 为 _ekernel 之后 4 KiB 的位置
    la a0, _ekernel
    li t0, 0x1000
    add sp, a0, t0

    # 1. 将 stvec 设置为 _traps
    la t0, _traps
    csrw stvec, t0

    # 2. 设置 sie[STIE]
    li t0, 0x20
    csrs sie, t0

    # 3. 设置第一次时钟中断的时间
    rdtime a0
    li t0, TIMECLOCK
    add a0, a0, t0

    li a7, 0x54494d45
    li a6, 0
    li a5, 0
    li a4, 0
    li a3, 0
    li a2, 0
    li a1, 0

    ecall

    # 4. 设置 sstatus[SIE]
    li t0, 0x2
    csrs sstatus, t0

    # 5. 跳转到 start_kernel
    j start_kernel