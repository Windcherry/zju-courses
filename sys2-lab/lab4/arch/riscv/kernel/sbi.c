#include <stdint.h>
#include <sbi.h>

struct sbiret sbi_ecall(uint64_t eid, uint64_t fid,
                        uint64_t arg0, uint64_t arg1, uint64_t arg2,
                        uint64_t arg3, uint64_t arg4, uint64_t arg5) {
    struct sbiret ret;
    
    asm volatile(
        "mv a7, %[input_eid]\n"
        "mv a6, %[input_fid]\n"
        "mv a0, %[input_arg0]\n"
        "mv a1, %[input_arg1]\n"
        "mv a2, %[input_arg2]\n"
        "mv a3, %[input_arg3]\n"
        "mv a4, %[input_arg4]\n"
        "mv a5, %[input_arg5]\n"
        "ecall\n"
        "mv %[error_code], a0\n"
        "mv %[ret_value], a1"

        : [error_code] "=r" (ret.error),
          [ret_value] "=r" (ret.value)
        : [input_eid] "r" (eid),
          [input_fid] "r" (fid),
          [input_arg0] "r" (arg0),
          [input_arg1] "r" (arg1),
          [input_arg2] "r" (arg2),
          [input_arg3] "r" (arg3),
          [input_arg4] "r" (arg4),
          [input_arg5] "r" (arg5)
        : "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "memory"
    );

    return ret;
}
