# Process

#### process concept

##### 进程概念

进程(process)是处于运行时的程序(program)，是程序的一个实例(instance)

注：word是程序，而打开多个word(进程)相当于是创建了该程序的多个实例

线程是操作系统调度的最小单元，进程是资源分配的实体

##### 进程组成

每个进程都需要有独立的数据结构来保存其信息

- **program code**(程序的代码)，也叫作`text section`

- **CPU states**，进程做上下文切换的时候，CPU的状态和信息(pc, registers, ...)都需要保存

- **various types of memory**，不同类型的内存：

    - stack，栈，存放临时变量，比如函数参数、局部变量、返回地址等

    - data section，数据段，存放全局变量

    - heap，堆，存放运行时刻动态申请的内存(malloc)

        <img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014113903549.png" alt="image-20201014113903549"  />

##### 进程的内存分布

每个进程都有自己的虚拟地址空间，在运行时刻，进程中不同类型的memory在地址空间中都有特定的分布位置

下图展示了，**程序被加载成为进程之后，地址空间中不同类型数据的分布情况**

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014113408444.png" alt="image-20201014113408444"  />

##### 进程的状态和状态传递

主要分为以下几种状态：

- new：进程被创建
- ready：进程已经准备好给处理器(CPU)执行
- running：进程的指令被执行
- waiting/blocking：进程等待某些事件的发生后再执行
- terminated：进程已经结束执行

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014114311683.png" alt="image-20201014114311683" style="zoom:80%;" />

#### Process Control Block(PCB)

##### PCB concept

操作系统是整个系统资源的管理者，它负责进程的创建、销毁、维护状态，而操作系统内核为了支持进程这个概念，需要维护一个叫做PCB的数据结构

内核本质上也是一段处于内核态的程序，它所维护的数据结构实际上就存放于内核程序的heap上，因此为了支持进程的抽象概念，它的heap中维护的数据结构之一就是PCB

PCB中保存的是进程的相关信息(pc, register, ...)，这些信息保证了不同进程在被调度时能够成功运行

- process number (pid)
- process state
- **program counter (PC)**：pc能够告诉操作系统下次调度进入该进程时该从哪里开始运行
- CPU registers
- CPU scheduling information
- memory-management data
- accounting data
- I/O status

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014115612591.png" alt="image-20201014115612591" style="zoom:80%;" />

##### PCB in Linux

在linux中，PCB是用`stak_struct`的结构体来描述的

下图中，每个struct的object都对应一个进程，不同object之间用双向链表连接

注：

- linux调度的最小单元是线程，而在内核中不详细区分进程和线程的概念，因此统一用task代替
- 为了支持一个进程中有多个线程，就需要维护类似PCB的TCB数据结构

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014115734014.png" alt="image-20201014115734014" style="zoom: 67%;" />

#### Process Scheduling

##### 进程调度

操作系统除了要维护进程的创建和状态之外，还需要对不同的进程进行调度，以保证每个进程能得到公平的时间片来执行

进程调度的发生是比较频繁的，由于操作系统Interrupt-driven的特性，定时器会定期使CPU发生中断，操作系统才有机会得到执行，就可以去进程调度(当前有多少进程在运行，进程的时间片是否用完，如果用完就轮换到ready队列中的新进程执行)

进程调度时从符合条件的队列中取一个“进程”出来执行，此时取出的是该进程的PCB，从PCB中可以取出该进程的上下文和pc进行设置，随后顺利执行

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014121555662.png" alt="image-20201014121555662" style="zoom:67%;" />

##### Swap In/Out

换入换出：当机器的内存资源不足以提供当前运行进程所需的memory，就可以把内存里的某个进程的数据和状态写到磁盘中

##### 不同的进程类型

进程主要分为两种类型：

- IO-bound：IO密集型，以读写为主
- CPU-bound：CPU(计算)密集型，以计算为主

##### Context Switch

上下文切换(context-switch)：

- 保存：把即将被调度出去的进程状态写入PCB中

- 加载：把即将运行的进程状态加载到CPU硬件的register里

context-switch is overhead，上下文切换实际上是一种开销，此时无论是被调度出去的进程还是被加载进来的进程都不处于运行状态，因此我们希望上下文切换的过程时间越短越好

下图演示了上下文切换的基本过程：

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014122549655.png" alt="image-20201014122549655" style="zoom: 80%;" />

#### Process Creation

进程是通过`fork()`系统调用创建出来的，而最初的进程是由操作系统主动创建的`init`进程

- 操作系统在自己加载完成之后，会主动去加载一个可执行程序，然后把它变成系统里的`init`进程，它是唯一不通过fork()创建的进程
- 新的进程都是由父进程通过fork system call创建出的子进程
- 所有新的进程都是`init`进程的子进程

父进程和子进程之间的关系：

- 资源共享可以是全共享(all)、部分共享(subset)和不共享(none)
- 在linux中，子进程是父进程完整的一份**拷贝**，也包括pc的拷贝(当前执行到的指令)
- 子进程可以通过`exec`加载新的程序(program)去override当前地址空间的可执行文件，以达到创建不同功能的新进程的目的
- 父进程可以通过`wait`来等待子进程的结束

举例：terminal本身就是一个进程，执行`ls`+回车，就会去`fork`新的子进程，并调用`exec`执行你在terminal中敲的`ls`命令，注意`ls`对应的是环境变量中的`bin/ls`可执行文件，这个program会被`exec`所加载

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014145251205.png" alt="image-20201014145251205" style="zoom:67%;" />

#### Process Termination

##### concept

进程的结束是通过`exit`系统调用实现的，父进程可以通过`wait`等待子进程的结束，也可以通过`abort`主动地结束子进程，并在子进程结束之后回收资源(resource)

如果父进程已经结束，子进程尚未结束，在linux中是没有任何问题的，但有些操作系统可能不允许

##### zombie vs orphan

zombie(僵尸进程)：

- 子进程已经结束，父进程没有调用wait等待子进程结束(此时父进程可能尚在执行或已经结束)，此时子进程被称为僵尸进程

- 尽管子进程已经结束，也还是不能在操作系统内核中把它分配的PCB的object资源给释放掉，因为不知道父进程的状态，万一父进程将来还会调用`wait`就会出错

orphan(孤儿进程)：

- 父进程已经结束，但没有调用`wait`，那么它所创建的所有子进程都变成了孤儿进程

- 操作系统会把所有孤儿进程的父进程重新设定为`system-d`，该程序会阶段性地调用`wait`，去检查是否有子进程已经结束而需要释放资源

父进程如果调用`wait` system call，就一定不会出现父进程已经结束而子进程还没有结束的情况，因为wait会阻塞(block)父进程直到子进程的结束

#### Android Process

安卓也是采用Linux Kernel，桌面操作系统很少主动kill进程，而手机操作系统基于耗电考虑，不太希望后台运行太多进程，不同类型的进程按照会被主动kill掉的可能性划分为不同等级

在安卓操作系统中，同样也有初始的`init`进程，但与linux操作系统不同的是，它多出来一个叫做`Zygote`的进程，所有其他的(应用)进程不是由`init`进程fork出来，而是由`Zygote`进程fork出来的，基于两个需求

- 用户点击应用加载速度要快

- 节约内存

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014151415285.png" alt="image-20201014151415285"  />

Zygote进程会把系统里的所有library和资源全部加载好：

- 优点：`Zygote`已经把一个app所有需要的资源预先加载好了，因此由它fork出来的子进程(完整拷贝)加载速度会非常快；此外还可以资源共享

    注：这里的拷贝不是指物理上的拷贝，而是在页表上修改一些指针信息

- 缺点：系统启动时fork `Zygote`进程会很慢；不同app中各种资源(如libc.so)的虚拟地址分布是相同的，容易被恶意攻击

#### Chrome Browser

chrome浏览器将不同的进程设计为不同的tab，从而实现进程隔离

如果两个tab处于同一个进程之中，则某个tab中加载的网站可以通过进程中共享的js引擎漏洞去访问甚至修改其他进程，降低了安全性

这样做的代价：多进程会占用比较多的内存资源

提高安全性的做法：

- 进程隔离
- 进程Policy权限限制(只允许使用部分功能)

#### Interprocess Communication

##### IPC concept

进程间通讯(Interprocess Communication, IPC)有两种模式：

- 共享内存(shared memory)：进程A和进程B共享同一块**physical memory**，通过页表的机制实现不同的虚拟地址指向同一个物理地址，也叫作双重映射(double mapping)，存在同步问题
- 消息传递(message passing)：内核参与，用内核里的一块数据(固定的buffer)做通讯媒介
    - blocking(阻塞)：同步模式(synchronous)，接收者没有接收发送者传递的消息
    - non-blocking(非阻塞)：异步模式(asynchronous)

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014161233763.png" alt="image-20201014161233763" style="zoom:67%;" />

##### linux做共享内存(POSIX)

POSIX Shared Memory

- shm_fd -> file descript文件描述符

- shm -> shared memory

- name：标识共享内存的名字

~~~c
shm_fd = shm_open(name, O CREAT | O RDWR, 0666);
~~~

`mmap()`可以把一段文件描述符(shm_fd)和一段内存关联映射起来

##### Pipes

管道也可以做进程间的交互通讯

- Ordinary Pipes(常规管道)：必须是父进程和子进程之间的关系，必须是单向的
- Named Pipes(命名管道)：双向

##### Client-Server Communication

- Sockets：套接字
- Remote procedure calls：RPC