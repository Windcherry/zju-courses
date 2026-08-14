#include <stdio.h>
#include <printk.h>
#include <sbi.h>

static int printk_sbi_write(FILE *restrict fp, const void *restrict buf, size_t len) {
  (void)fp;

  const unsigned char *p = (const unsigned char *)buf;
  size_t i;
  
  for (i = 0; i < len; i++) {
      struct sbiret ret = sbi_ecall(0x01, 0, (uint64_t)p[i], 0, 0, 0, 0, 0);

      if (ret.error != 0) {
          return i;
      }
  }

  return (int)len;

}

void printk(const char *fmt, ...) {
  FILE printk_out = {
      .write = printk_sbi_write,
  };

  va_list ap;
  va_start(ap, fmt);
  vfprintf(&printk_out, fmt, ap);
  va_end(ap);
}
