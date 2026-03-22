#include <printk.h>
#include <sbi.h>
#include <private_kdefs.h>

_Noreturn static void test(void) __attribute__((noinline));
_Noreturn static void test(void) {
  uint64_t last_timeval = 0;

  while (1) {
    uint64_t timeval;
    asm volatile("rdtime %0" : "=r"(timeval));
    timeval /= TIMECLOCK;
    if (timeval != last_timeval) {
      last_timeval = timeval;
      printk("Kernel is running! timeval = %" PRIu64 "\n", timeval);
    }
  }
}

_Noreturn void start_kernel(void) {
  csr_write(sscratch, 0x7e9);
  printk("%ld", csr_read(sscratch));
  printk(" ZJU Computer System II\n");

  test();
}
