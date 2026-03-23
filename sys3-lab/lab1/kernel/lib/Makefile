ASM_SRC := $(wildcard *.S)
C_SRC := $(wildcard *.c)
OBJ := $(ASM_SRC:.S=.o) $(C_SRC:.c=.o)

.PHONY: all clean

all: $(OBJ)

clean:
	rm -f *.o

%.o: %.S
	$(GCC) $(CFLAG) -c $< -o $@

%.o: %.c
	$(GCC) $(CFLAG) -c $< -o $@
