# Kernel BootLoader

#### 编写makefile

这里主要分为4个makefile文件，将分别阐述其作用

##### makefile_top

为了避免文件层级调用时出现相对路径的错误，这里使用全局变量`TOP`来保存顶层目录，并作为参数export到各级子目录下，供各级makefile使用

同理，`RISCV`、`INC`、`INIT`、`OBJ`都是基于绝对路径的文件目录

`CROSS`相关变量是riscv64的编译工具，`INCLUDE`为gcc提供了`.h`的路径，避免找不到对应依赖库

`all`是伪目标，它依赖于两个功能：

- `CHECKDIR`：用于查看是否存在`$(TOP)/obj`目录，若不存在则创建
- `MAKE`：用于进入各级子目录并利用`make -C`递归调用执行该子目录下的makefile文件

`clean`：使用`make clean`命令可以清除由make产生的所有相关文件

`run`：使用`make run`命令可以直接使用qemu启动kernel，并执行`start_kernel`中的函数

代码如下：

~~~makefile
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
~~~

##### makefile_init

init目录下的makefile主要功能是利用top层提供的编译参数将`main.c`和`test.c`编译生成对应的`main.o`和`test.o`文件，并统一存放到`$(TOP)/obj`目录下

代码如下：

~~~bash
all : $(OBJ)/main.o $(OBJ)/test.o

$(OBJ)/main.o : main.c
	$(GCC) $(CFLAG) -o $@ -c $<

$(OBJ)/test.o : test.c
	$(GCC) $(CFLAG) -o $@ -c $<
~~~

##### makefile_kernel

kernel目录下的makefile主要功能是利用自行编写的`head.S`文件编译生成对应的`head.o`文件，并统一存放到`$(TOP)/obj`目录下

代码如下：

~~~makefile
all : $(OBJ)/head.o

$(OBJ)/head.o : head.S 
	$(GCC) $(CFLAG) -o $@ -c $<
~~~

##### makefile_riscv

riscv目录下的makefile主要有4个功能，因此同样需要用伪目标`all`来实现：

- `KERNEL`：调用kernel目录下的makefile文件
- `vmlinux`：利用GNU ld链接器将`$(TOP)/obj`目录下的`main.o`、`test.o`、`head.o`文件根据`vmlinux.lds`链接脚本中的内存分布，来链接生成最终的可执行文件`vmlinux`，并存放到`$(TOP)/`目录下
- `System.map`：内核符号表存储了链接完成后的全局变量和函数名的内存地址，这里用`nm linux`命令打印`vmlinux`的符号表，并通过重定向`>`输出到`$(TOP)/System.map`中
- `Image`：Image是使用objcopy丢弃调试信息和符号表从而生成的`vmlinux`的精简版二进制文件，这里使用顶层目录传来的`$(OBJCOPY)`编译参数来生成，并存放到`boot/Image`目录下

代码如下：

~~~makefile
all : KERNEL vmlinux System.map Image

KERNEL:
	make -C $(RISCV)/kernel

vmlinux:
	$(LD) $(OBJ)/main.o $(OBJ)/test.o $(OBJ)/head.o -T kernel/vmlinux.lds -o $(TOP)/vmlinux

System.map:
	nm $(TOP)/vmlinux > $(TOP)/System.map

Image:
	$(OBJCOPY) -O binary $(TOP)/vmlinux boot/Image --strip-all
~~~

#### 编写head.S

head.S的主要功能是关闭中断、模式切换和C程序跳转

对RISCV来说，一个硬件线程(hardware thread, hart)会运行在某个特权级别当中，该特权级别会作为模式编码在CSRs(control and status registers)即控制状态寄存器组中，共三种特权模式：

| 级别 | 编码 |    名字     | 缩写 |
| :--: | :--: | :---------: | :--: |
|  0   |  00  | 用户/应用级 |  U   |
|  1   |  01  |   特权级    |  P   |
|  3   |  11  |   机器级    |  M   |

每个特权级别都有属于它的一个指令子集，机器级是最高的特权级别，可以运行任何指令，访问处理器中任何的一个寄存器，而RISCV CPU加电后的初始状态也就运行在M Mode上，我们要实现的OS内核要运行在S Mode上

这里比较重要的是对`mstatus`寄存器的控制，其基本结构如下：

![avatar](http://www.sunnychen.top/images/mstatus-RV32.png)

bootloader本身可以理解成是一个"异常"，因此需要先关闭全局中断，处理当前"异常"(基本硬件设备初始化、设置堆栈、异常返回地址等)：

- `mstatus.MIE`域的值需要被更新成为0，意味着进入异常服务程序后中断被全局关闭，所有的中断都将被屏蔽不响应

    注：MIE、SIE以及UIE这些位用于表明当前特权级的全局中断使能情况，当一个hart在x特权级执行时，若xIE=1，则此特权级下允许中断

- 更新`mepc`寄存器的值(在代码中是`super`标签地址)，该寄存器将作为退出异常的返回地址，在异常结束之后，能够使用它保存的PC值回到之前被异常停止执行的程序点

    注：`mtvec`记录遇到异常后跳转地址，`mepc`记录异常结束后的跳转地址

- 修改`mstatus`寄存器中`MPP=01`，对应即将切换的目标模式`S Mode`

    注：`xPP`保存着异常发生前的特权模式，MPP有2位，SPP只有1位，而UPP是隐式为0的(异常进入用户模式只能是用户模式，异常进入特权模式可以是用户模式也可以是特权模式，异常进入机器模式则可以是所有的模式)，因此执行`mret`后会切换回之前保留在`xPP`里的特权模式，这也是模式切换的依据所在

随后执行`mret`指令进行M->S的模式切换，并且程序跳转到`mepc`保存的地址上开始执行

基本运行过程可以总结为，在`head.S`中先令`mstatus.MIE=0`以关闭全局中断，再令`status.MPP=01`设置为要切换的S模式，并将异常结束后要跳转的地址`super`保存到`mepc`，再执行`mret`，就可以切换到S模式，并从mepc保存的地址上开始继续执行汇编程序

最后，由于汇编开头已经用`la sp, stack_top`设置好了C语言调用栈环境，因此直接调用main.c里的`start_kernel`函数即可跳转

注：这里修改栈指针寄存器 `sp` 为段结束地址，是因为栈是从高地址往低地址增长，所以高地址是初始的栈顶；此外，`head.S`里的函数分布需要符合`vmlinux.lds`里的描述

具体代码如下：

~~~assembly
.text

.global _start
_start:
la      sp, stack_top   # 设置sp为栈顶

li      t0, 8
csrc    mstatus, t0     # 关闭全局中断

li      t0, 0x0800
csrs    mstatus, t0
li      t0, 0x1000
csrc    mstatus, t0     # 设置MPP=01,即S模式

la      t0, super       # 把标签地址写到t0里
csrw    mepc, t0        # t0的值赋给mepc
mret                    # mret，切换到S模式，并跳转到super

.global super
super:
la      t0, stack_top
csrw    sepc, t0
addi    sp, sp, -100    # 非必须
call    start_kernel
addi    sp, sp, 100     # 非必须

.global stack_top
stack_top:

.global _end
_end:
~~~

#### 运行结果

运行`make`前的初始结构：

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/lab/img/image-20201012093123094.png" alt="image-20201012093123094" style="zoom:80%;" />



`make`执行过程：

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/lab/img/image-20201012093231351.png" alt="image-20201012093231351" style="zoom:67%;" />

`make`执行完成后的最终结构：

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/lab/img/image-20201012093316832.png" alt="image-20201012093316832" style="zoom:80%;" />

执行`make run`，输出`Hello RISC-V!`，说明结果运行成功！

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/lab/img/image-20201012093425978.png" alt="image-20201012093425978" style="zoom:80%;" />

