#include <printk.h>
#include <proc.h>

_Noreturn void start_kernel(void) {
  task_init();
  printk("2026 ZJU Computer System III\n");

  // 等待第一次时钟中断
  while (1)
    ;
}