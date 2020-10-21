all : KERNEL vmlinux System.map Image

KERNEL:
	make -C $(RISCV)/kernel

vmlinux:
	$(LD) $(OBJ)/main.o $(OBJ)/test.o $(OBJ)/head.o -T kernel/vmlinux.lds -o $(TOP)/vmlinux

System.map:
	nm $(TOP)/vmlinux > $(TOP)/System.map

Image:
	$(OBJCOPY) -O binary $(TOP)/vmlinux boot/Image --strip-all
