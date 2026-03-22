#include "private_kdefs.h"
    .section .text.entry
    .align 4
    .globl _traps
    .globl __dummy
    .globl __switch_to
_traps:
    # 1. 将寄存器和 sepc 保存到栈上
    addi sp, sp, -0x100

    sd x1, 8(sp)
    sd x3, 24(sp)
    sd x4, 32(sp)
    sd x5, 40(sp)
    sd x6, 48(sp)
    sd x7, 56(sp)
    sd x8, 64(sp)
    sd x9, 72(sp)
    sd x10, 80(sp)
    sd x11, 88(sp)
    sd x12, 96(sp)
    sd x13, 104(sp)
    sd x14, 112(sp)
    sd x15, 120(sp)
    sd x16, 128(sp)
    sd x17, 136(sp)
    sd x18, 144(sp)
    sd x19, 152(sp)
    sd x20, 160(sp)
    sd x21, 168(sp)
    sd x22, 176(sp)
    sd x23, 184(sp)
    sd x24, 192(sp)
    sd x25, 200(sp)
    sd x26, 208(sp)
    sd x27, 216(sp)
    sd x28, 224(sp)
    sd x29, 232(sp)
    sd x30, 240(sp)
    sd x31, 248(sp)

    csrr t0, sepc
    sd t0, 0(sp)


    # 2. 调用 trap_handler
    csrr a0, scause
    ld a1, 0(sp)
    
    call trap_handler

    # 3. 恢复寄存器和 sepc
    #    特别注意 sp 寄存器的恢复
    ld t0, 0(sp)
    csrw sepc, t0

    ld x31, 248(sp)
    ld x30, 240(sp)
    ld x29, 232(sp)
    ld x28, 224(sp)
    ld x27, 216(sp)
    ld x26, 208(sp)
    ld x25, 200(sp)
    ld x24, 192(sp)
    ld x23, 184(sp)
    ld x22, 176(sp)
    ld x21, 168(sp)
    ld x20, 160(sp)
    ld x19, 152(sp)
    ld x18, 144(sp)
    ld x17, 136(sp)
    ld x16, 128(sp)
    ld x15, 120(sp)
    ld x14, 112(sp)
    ld x13, 104(sp)
    ld x12, 96(sp)
    ld x11, 88(sp)
    ld x10, 80(sp)
    ld x9, 72(sp)
    ld x8, 64(sp)
    ld x7, 56(sp)
    ld x6, 48(sp)
    ld x5, 40(sp)
    ld x4, 32(sp)
    ld x3, 24(sp)
    ld x1, 8(sp)

    addi sp, sp, 0x100

    # 4. 返回
    sret

__dummy:
    la t0, dummy_task
    csrw sepc, t0
    sret

__switch_to:
    # 1. 将当前线程的上下文保存到当前线程的 thread_struct 中
    # a0: prev, a1: next
    # 由于 thread_struct 是 task_struct 的内容，计算偏移量时需要考虑 task_struct 其他字段
    sd ra, OFFSET_THREAD_STRUCT + 0(a0)
    sd sp, OFFSET_THREAD_STRUCT + 8(a0)

    sd s0, OFFSET_THREAD_STRUCT + 16(a0)
    sd s1, OFFSET_THREAD_STRUCT + 24(a0)
    sd s2, OFFSET_THREAD_STRUCT + 32(a0)
    sd s3, OFFSET_THREAD_STRUCT + 40(a0)
    sd s4, OFFSET_THREAD_STRUCT + 48(a0)
    sd s5, OFFSET_THREAD_STRUCT + 56(a0)
    sd s6, OFFSET_THREAD_STRUCT + 64(a0)
    sd s7, OFFSET_THREAD_STRUCT + 72(a0)
    sd s8, OFFSET_THREAD_STRUCT + 80(a0)
    sd s9, OFFSET_THREAD_STRUCT + 88(a0)
    sd s10, OFFSET_THREAD_STRUCT + 96(a0)
    sd s11, OFFSET_THREAD_STRUCT + 104(a0)

    # 2. 从下一个线程的 thread_struct 中恢复上下文
    ld ra, OFFSET_THREAD_STRUCT + 0(a1)
    ld sp, OFFSET_THREAD_STRUCT + 8(a1)

    ld s0, OFFSET_THREAD_STRUCT + 16(a1)
    ld s1, OFFSET_THREAD_STRUCT + 24(a1)
    ld s2, OFFSET_THREAD_STRUCT + 32(a1)
    ld s3, OFFSET_THREAD_STRUCT + 40(a1)
    ld s4, OFFSET_THREAD_STRUCT + 48(a1)
    ld s5, OFFSET_THREAD_STRUCT + 56(a1)
    ld s6, OFFSET_THREAD_STRUCT + 64(a1)
    ld s7, OFFSET_THREAD_STRUCT + 72(a1)
    ld s8, OFFSET_THREAD_STRUCT + 80(a1)
    ld s9, OFFSET_THREAD_STRUCT + 88(a1)
    ld s10, OFFSET_THREAD_STRUCT + 96(a1)
    ld s11, OFFSET_THREAD_STRUCT + 104(a1)

    # 3. 返回
    ret

