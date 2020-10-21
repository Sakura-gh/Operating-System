.text

.global _start
_start:
la      sp, stack_top   # 这是导致失败的罪魁祸首,需要给sp一定的初值才行，不能为0
#li      t0, 0x4000     # 随便给sp一个初始值也可以正常运行
#add     sp, sp, t0

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
addi    sp, sp, -100    # 这里的sp空间申请并不是必须的
call    start_kernel
addi    sp, sp, 100     # 非必须

.global stack_top
stack_top:

.global _end
_end:

