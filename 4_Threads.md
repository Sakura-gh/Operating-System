# Threads

#### Thread

##### 线程 vs 子进程

- 创建子进程相比于创建线程是一个比较“重”的操作

- 进程之间通讯需要IPC机制，而线程之间天生有共享资源的特性，因为多个线程共享进程的地址空间，可以利用全局变量来通讯

##### Concept

线程是一系列可以独立运行的指令序列

假设program中有func A()和func B()

- 对进程来说，某个进程的PC在同一时刻要么属于A，要么属于B
- 对线程来说，有类似PCB概念的TCB，每个线程都拥有自己的PC，可以分别运行A和B

进程和线程最显著的区别是，**线程是可以被独立调度的**，拥有自己的PC，并且能够share进程的部分资源(code、heap、data...)

多线程的优势：

- 在单核下，多线程可以有更高的概率获取时间片
- 在多核下，多线程可以直接在多个核心(CPU)同时刻并行执行

当然每个线程还有自己的独立资源：

- stack：函数调用时保存参数、返回值、局部变量
- pc：保证能够被单独调度
- thread-specific data：以**TLS**修饰的变量只能被某个线程访问，而不能被其他线程访问(类似static)

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014172227632.png" alt="image-20201014172227632" style="zoom:67%;" />

多线程的好处：

- responsiveness：响应性更好
- resource sharing：天生共享资源
- economy：创建线程快于进程
- scalability：在多核(CPU)的架构上有更好的并发性，多个线程可以同时单独运行在不同的CPU上

#### Concurrency vs Parallelism

**并发**(concurrency)：并发更关心程序的**结构**(structure)，如何将一个任务**切分**成多个能够相互交互的小任务(计算单元)，并不强制要求要同时执行

**并行**(Parallelism)：并行更关心程序的**执行**(execution)，它要求多任务必须**同时**执行

#### Implement Threads

##### user/kernel threads

线程有两种类型：

- user threads：在用户态实现线程
- kernel threads：在内核态实现线程

如果只有用户态实现线程，那么在内核里没有线程的概念，它只认识进程，一个进程里的多个用户态线程是由用户态运行时系统来进行调度的，这会造成内核的调度仍然以进程为单元，即每个线程得到时间片仍然是它所属进程的时间片，而非线程单独的时间片

##### kernel-level threads

实现**内核态线程**后，内核就会维护每个线程的TCB，此时线程就是内核调度的基本单元(内核也知道每个线程所归属的进程)

因为内核明确知道线程的概念，所有操作系统需要提供系统调用去创建和管理线程

- 优点：某个进程拥有更多线程就意味着可以从内核中获得更多的时间片

- 缺点：耗费资源，创建内核线程需要系统调用、速度慢；对TCB的维护加重了内核的开销和复杂度

##### User-level threads

实现**用户态线程**：

- 优点：即使操作系统内核不支持线程的概念，也可以在用户态模拟出线程，而不用对内核进行修改，管理简单，线程的切换和创建都比较简单，不需要通过系统调用来实现
- 缺点：操作系统内核不理解线程的概念，做出的调度策略不一定最优

##### user/kernel thread relationship

###### Many-to-one

多对一

等价于内核不支持线程的情况，多个user thread对应一个kernel thread(即process)

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014200441749.png" alt="image-20201014200441749" style="zoom:67%;" />

###### One-to-One

一对一，这也是Linux所采用的方法

每创建一个用户态线程，就要创建对应的内核态线程

可以理解为每个用户态的线程在内核中都有对应的PCB结构

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014200700935.png" alt="image-20201014200700935" style="zoom:67%;" />

###### Many-to-Many

多对多

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014200846084.png" alt="image-20201014200846084" style="zoom:67%;" />

#### Threading Issues

##### Thread Cancellation

线程终止的方法：

- 在线程运行时直接kill，可能会导致部分被访问的资源没有被释放
- 在线程上做mark标记位，如果某个线程观察到有人要kill自己，就先释放自己占用的资源，再自动终止

##### Thread Specific Data

TLS(Thread-local storage)变量修饰符允许每个线程拥有自己的全局变量

TLS修饰的变量与局部变量不同，它更像是c/c++中的static变量，它创建了**只**对某个线程可见的全局变量的拷贝

##### Lightweight Process

在书中的定义是，如果内核线程和用户态线程之间不是像linux一样one-to-one映射，就需要用LWP来描述它们之间的关系

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014202522419.png" alt="image-20201014202522419" style="zoom:67%;" />

而在linux中，LWP指的就是内核线程，此外创建线程的过程和创建进程的方法很相似，只是一些flag有差异，这也是linux用LWP命名内核线程的原因

##### Linux Threads

为了创建内核线程(LWP)，linux提供了`clone`系统调用，`clone`可以理解成是带参数的`fork`，`clone`可以用一些`flag`来指定父与子之间有哪些资源的共享或不共享的

如果`clone`指定文件系统、虚拟地址空间、信号处理、文件等资源的`flag`都为共享，则表明创建了线程；如果这些`flag`都设为不共享，则表示创建的仅是拷贝，相当于是`fork`

<img src="/media/gehao/Data/gehao/Documents/CS/Operating-System/notes/img/image-20201014203428838.png" alt="image-20201014203428838" style="zoom:80%;" />



