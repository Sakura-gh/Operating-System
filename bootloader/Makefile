TOP = $(shell pwd)
RISCV = $(TOP)/arch/riscv
INC = $(TOP)/include
INIT = $(TOP)/init

OBJ = $(TOP)/obj

CROSS_= riscv64-unknown-elf-
AR=${CROSS_}ar
GCC=${CROSS_}gcc
LD=${CROSS_}ld
OBJCOPY=${CROSS_}objcopy

ISA ?= rv64imafd
ABI ?= lp64

INCLUDE = -I ../include
CF =  -O3 -march=$(ISA) -mabi=$(ABI) -mcmodel=medany -ffunction-sections -fdata-sections -nostartfiles -nostdlib -nostdinc -static -lgcc -Wl,--nmagic -Wl,--gc-sections
CFLAG = ${CF} ${INCLUDE}

export GCC CFLAG OBJ CROSS_ AR LD OBJCOPY TOP RISCV

all : CHECKDIR MAKE

CHECKDIR:
	mkdir -p $(OBJ)

MAKE:
	make -C $(INIT)
	make -C $(RISCV)

.PHONY:clean
clean:
	rm -rf $(OBJ) $(TOP)/vmlinux $(TOP)/System.map $(RISCV)/boot/Image

run:
	qemu-system-riscv64 -nographic -machine virt -kernel vmlinux
