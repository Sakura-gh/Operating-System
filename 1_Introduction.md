# Introduction

#### component and device

计算机系统的四个组件：

- hardware：硬件，如CPU、memory和IO devices
- operating system：操作系统
- application：应用程序
- users：用户

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200922155807801.png" alt="image-20200922155807801" style="zoom: 80%;" />

其中操作系统的主要作用是：**资源管理和调度**，管理计算机的硬件资源并做调度，保证硬件资源不能只被某个应用程序占据

程序分为特权程序(如linux下的root特权)和普通程序，对应的是内核态和用户态

操作系统能做什么，可以从用户的角度看(user view)，也可以从系统的角度看(system view)

- OS is a resource allocator：操作系统是(硬件)资源的分配(管理)者，需要保证请求不冲突及分配公平

    注：这里的资源可以被理解成hardware resource，os在底层分配硬件资源从而支持应用程序的运行

- OS is a control program：操作系统是一个控制程序，用户态的程序需要在操作系统底层受到控制，否则一个用户程序就可以去access另一个用户程序的数据，互相干扰，这从安全、容错的角度来看都是不可接受的

操作系统并没有非常准确的定义，本课程更多的是关注操作系统的**内核(kernel)**，包含调动CPU、分配虚拟内存等功能

操作系统管理的硬件资源包括：

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200922161236587.png" alt="image-20200922161236587"  />

各种各样的设备想要运转起来都需要一个叫做控制器(device controller)的东西，每个device controller都会含有一个local buffer

操作系统和controller打交道的地方就叫做驱动(device driver)，一般人们所讲的内核(Kernel)都是包含驱动的，驱动是能让连接到计算机系统的外设能够正常运转所需的部分软件，它会告诉controller要做什么事情(把控制信号写入controller)，从而使得controller能够正确地去控制外部设备做事情

此外，IO操作和CPU可以同步运行，即可以把数据直接从外设送到memory里，而并不一定需要CPU的参与，这也就是DMA(direct memory access)的概念

#### Interrupts and Traps

##### Interrupt(硬中断)

**异步中断**(asynchronous)：中断的发生不以CPU的意志为转移，CPU无法控制中断的发生；比如键盘打字就会触发中断，但CPU是无法控制用户在什么时候打字的

外设通过中断机制来通知CPU当前有事情正在发生，此时CPU自动使PC跳到预先在中断向量表中设定好的位置，即中断处理程序所在位置，操作系统开始介入，处理完中断后，恢复到之前被打断的程序执行点上

操作系统是Interrupt-driven的system，比如有多个进程(process)想要使用CPU的资源，需要轮流执行，可以让定时器(Timer)每20ms给一个中断，然后操作系统介入进行资源的调度

定时器改进：on-demand timer Interrupts，避免定时中断导致耗电和CPU空转，而是在需要中断的时候才触发

##### Trap(软中断)

**同步中断**(synchronous)：中断的产生并不是由硬件或定时器事件触发的，而是由操作系统内核或用户程序在需要CPU做某件事情的时候主动触发的；最典型的就是**系统调用(system call)**，比如C语言中调用文件的open操作

##### Interrupt Handling

CPU里为了让一个进程正确执行所需要获取的信息，叫做PCB(process control block)，它是中断时所保存数据(context)的一部分

操作系统判断哪个设备引起中断的方式：

- polling：遍历寻找哪个设备造成中断
- vectored interrupt system：跳到设备特定的中断向量

##### IO

应用程序是通过系统库提供的API函数来操作IO设备的，最常见的是open、read、write

例：open函数通过open system call使得操作系统介入，程序的执行从用户态切换到内核态，IO请求被发送至设备驱动，进而发送至设备控制器，最终完成IO设备的操作

#### Storage Structure

主要是主存(Main memory)和缓存(cache)的管理，将会在文件系统一章详细介绍

- volatile：易失性的，掉电数据易丢失
- nonvolatile：非易失性的，掉电数据不易丢失

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200922173812114.png" alt="image-20200922173812114"  />

程序是不直接跟物理地址(physical address)打交道的，每个程序都会认为自己拥有完整的虚拟地址(virtual address)空间，但对每个进程来说，相同的虚拟地址不一定指向相同的物理地址

#### Multi-processor Systems

多处理器系统的难点：cache的一致性

##### 多处理器(multiple-processor)

在主板上集成多个物理的CPU

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926102050863.png" alt="image-20200926102050863" style="zoom:80%;" />

##### 多核(multi-core)

在一个物理的CPU上集成了多个CPU

- 多核结构中不同CPU之间的通信要比多处理器通过主板总线通信要来的快

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926102111039.png" alt="image-20200926102111039" style="zoom:80%;" />

##### Multi Core Vs Hyper Threading

多核与超线程

注意，一个物理的CPU上所能塞进去的CPU core是有限的，目前常用的是8核心结构，为了能够进一步榨取硬件的性能，就有了**超线程**(Hyper Threading)的概念

比如下图中一个物理的CPU芯片有4个CPU core，每个core都有自己独立的取指、译码、执行等功能，但总是会有一些事情(如cache miss)会让流水线(pipeline)不能满载运转

为了让CPU core运行得更好，可以令每个核心为**多个取指令的单元+一个执行单元**的组合，这样当某个取指单元miss的时候，其他的取指单元还可以顺利地抓到有效指令(多个爪子抓娃娃?)，以实现抓取指令的并行化，从而使得执行单元每时每刻都在运转，这就是超线程的概念

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926102744638.png" alt="image-20200926102744638" style="zoom:80%;" />

在操作系统的内部，它会把超线程也认为是一个逻辑上的CPU，比如4个核心，每个核心有2个线程，则被认为具有8个逻辑CPU

#### Dual-mode Operation

硬件必须要支持两个或多个特权模式

典型的双模式：

- **特权模式(内核态)**，直接操纵硬件设备和CPU的页表
- **非特权模式(用户态)**，不能直接访问IO，不能换页表，只能做计算(加减乘除、浮点运算、控制流跳转)

底层硬件在有了这两个模式的支撑之后，操作系统才能完成资源管理和程序控制的作用；如果用户程序可以直接操纵硬件和更改页表，那操作系统就完全没办法去做资源管理和调度了

这两个模式分别对应着用户态和内核态：

- 用户态(**usr mode**)：跑用户程序
- 内核态(**kernel mode**)：跑操作系统内核和驱动

当system call的时候，用户态就会被切换到内核态，操作系统帮忙完成相关任务

实际上用户态的程序虽然不能直接操纵硬件资源，但它也存在这样的需求，就需要通过system call让CPU切换到内核态，让内核态的驱动去实现打开文件、读取数据、操作外设等功能

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926110423467.png" alt="image-20200926110423467" style="zoom:90%;" />

在一些简单的操作系统(如嵌入式系统)中，用户态和内核态是不区分的

提权：一个应用态的程序能够利用操作系统的缺陷能把自己的权限提高至内核态

#### Resource Management: Process Management

操作系统是资源管理器，即进程管理器

##### 进程

进程(process)：a program in execution，**进程是处在运行时的program(程序)的instance(实例)**，每个进程都需要资源(resource)去完成相应的任务，比如memory、IO、CPU的resource

比如同时开几个word，每个word都是一个进程，但word的程序只有一个，每个进程都是这个程序的一个实例

from program to process：

- 栈(stack)：传递参数、存放局部变量
- 堆(heap)：处理在运行时动态分配的内存(如malloc)

##### 进程管理

每个进程都有自己的状态，在整个运行过程中，进程会随着不同的事件而不停地做状态迁移

如果一个进程处于running状态，且发送了IO请求，由于IO的响应时间较长，不能让该进程继续占用CPU资源导致CPU进入等待状态，因此操作系统会把该进程从running状态的队列中取出并放到blocked状态的队列中，再把处于ready状态的某个进程调度进running状态

如果一个进程是计算密集型的任务，使CPU持续运算了整个时间段且还未得到结果，此时也需要把它丢到ready状态的队列中，以等待下一轮的running

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926113016223.png" alt="image-20200926113016223"  />

##### 并行和并发的区别

- **并发**是只有一个CPU core，它轮流运行多个任务让你感觉上是多个进程在同时运行

- **并行**是真正地在同一个时刻，多于一个进程在不同的CPU core上运行

#### Program, Process and Thread

==程序、进程和线程的区别==

进程(process)是程序(program)运行的一个实例(instance)，各进程之间相互隔离，都认为自己有完整的虚拟地址空间，并且都会申请系统资源(resource)；每个进程都有自己的PC，表示该进程正在执行的instruction在哪，如果CPU资源被其他进程使用，将来可利用该PC跳转到该进程正确的指令执行地址上

一个进程(process)可以划分为多个线程(thread)，每个线程也有自己的PC，这意味着此时每个线程是被CPU调度的实体；线程是CPU和操作系统调度的基本单元，或者说是唯一调度的实体

注：在有些操作系统设计中，把进程作为唯一调度的实体，此时切分为线程的意义就没有那么大了；如果不同线程拥有各自独立的时间线，就可以分别做不同的事情；那为什么不直接把这些线程变成多个进程呢？这是因为同一个进程的不同线程在做事情的时候，相互之间可以共享resource(资源和信息)，比如全局的buffer，这是在同一个进程中共享一套相同的虚拟地址空间所带来的便利，如果不同的进程之间想要交换数据就会比较麻烦

当然，线程的使用也有缺点：互相访问数据导致安全性贬低、线程之间的数据同步问题

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926164547567.png" alt="image-20200926164547567" style="zoom:67%;" />

#### Mechanism and Policy

机制和策略区别：

- 机制(**Mechanism**)指提供底层的支持，能够帮你做什么事，比如操作系统提供了调度的机制，能够使不同进程能够轮流使用CPU资源
- 策略(**Policy**)指具体要做什么事，比如决定具体多长时间才能轮流切换一次CPU资源

安全性举例：

- 安卓把每个app都当做一个用户(uid不同)，形成天然的资源隔离

#### Virtualization

虚拟化概念，表达是**抽象**，通过虚拟化技术，提供上层用户统一的抽象内容，而不用管底层真正的实现

在下图中，可以在VM上run多个操作系统的内核，为os提供硬件层面的虚拟化，相当于一台物理机可以抽象出多个操作系统，适用于云服务器的应用场景

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926172328613.png" alt="image-20200926172328613" style="zoom:67%;" />

所谓抽象，就是把一个system分成很多层，每一层只需要关心需要对上一层提供什么样的接口，能够使用下一层提供的什么接口，而无需关心上下层的实现细节

- 优点：健壮性、兼容性较好
- 缺点：应用层离CPU层太远，导致它并不知道CPU是如何调度的、操作系统的driver是如何去访问外设的，但是某些专用的应用对访问IO的方式有一定的要求，比如数据库，如果无法控制底层IO优化的策略，就无法提高整体性能，因此需要给应用层提供一些硬件的接口(外内核的概念)
- 因此孰优孰劣，只能是具体场景具体分析

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926172547200.png" alt="image-20200926172547200" style="zoom:67%;" />

#### Other System

##### NUMA

在前面的讨论中，都是多个CPU共享一个memory的架构，而NUMA则是每个CPU都有自己的physical memory，并通过总线互相连接

- 优点：速度快，带宽高
- 缺点：如果某个CPU要访问其他CPU的memory就会很慢

<img src="https://cdn.jsdelivr.net/gh/Sakura-gh/Operation-System/img/image-20200926104408144.png" alt="image-20200926104408144" style="zoom:80%;" />

##### Clustered System

集群操作系统，多台PC通过高速网络相连，通常应用于云端

##### Distributed System

分布式操作系统

##### Special-Purpose System

特殊操作系统

- SSD硬盘的控制器里存在操作系统，用于安排内存访问位置，防止某些区域易于损坏
- 无线网卡里也存在操作系统，用于硬件提速和更灵活地配置环境