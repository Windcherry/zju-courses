# /arch/riscv/kernel/Makefile
INCLUDE_FLAGS := -I../include -I../../../include

C_SRCS := $(wildcard *.c)
S_SRCS := $(wildcard *.S)

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
