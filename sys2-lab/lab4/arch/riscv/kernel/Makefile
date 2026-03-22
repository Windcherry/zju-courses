# /arch/riscv/kernel/Makefile
INCLUDE_FLAGS := -I../include -I../../../include

C_SRCS := main.c print.c sbi.c
S_SRCS := head.S

OBJS := $(C_SRCS:.c=.o) $(S_SRCS:.S=.o)

.PHONY: all clean

all: $(OBJS)
	@echo "Kernel objects built in $(CURDIR)"

%.o: %.c
	$(GCC) $(CFLAGS) $(INCLUDE_FLAGS) -c $< -o $@

%.o: %.S
	$(GCC) $(CFLAGS) $(INCLUDE_FLAGS) -c $< -o $@

clean:
	rm -f $(OBJS)
