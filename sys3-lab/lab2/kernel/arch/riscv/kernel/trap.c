#include <stdint.h>
#include <printk.h>
#include <proc.h>

#define SCAUSE_INTERRUPT (1UL << 63)
#define STI_CODE 5

void clock_set_next_event(void);

void trap_handler(uint64_t scause, uint64_t sepc){
  // 1. 中断处理 (scause 最高位为 1)
  if (scause & SCAUSE_INTERRUPT){
    uint64_t interrupt_type = scause & (~SCAUSE_INTERRUPT);

    if (interrupt_type == STI_CODE){
      // printk("[S] Supervisor Timer Interrupt! scause: 0x%lx, sepc: 0x%lx\n", scause, sepc);
      clock_set_next_event();
      do_timer();
    }
    else{
      printk("[S] Unknown Interrupt! Code: 0x%lx, sepc: 0x%lx\n", scause, sepc);
    }
  } 
  // 2. 异常处理 (scause 最高位为 0) 
  else{
    uint64_t exception_code = scause;
    printk("[S] Exception! Code: %ld, sepc: 0x%lx. Halting...\n", exception_code, sepc);

    // 遇到异常，进入死循环防止无限 Trap
    while (1) {}
  }
}
