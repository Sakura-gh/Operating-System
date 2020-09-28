# Services and Structures

> 本章最重要的内容是系统调用和程序加载，以及操作系统结构(微内核、外内核、整体内核等)

#### OS Services

对操作系统来说，我们一般讨论的是内核(Kernel)，其大致结构如下图所示，硬件->操作系统内核->system call->应用程序->用户

应用程序和操作系统打交道的途径是系统调用(system call)，API是对系统调用的封装，系统调用是通过trap软中断的方式来实现的，完成了从用户态到内核态的转变，其中有三种系统调用传参的方式(register、block、stack)



<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926191458714.png" alt="image-20200926191458714" style="zoom: 67%;" />

#### System Call

##### 定义和流程

定义：System call is a programming interface to access the OS services，系统调用是用户态访问操作系统提供服务的接口

大致流程：user调用API->调用system call->操作系统介入->访问resource

`cp in.txt out.txt`所触发的system call：在键盘接收输入、屏幕显示输出、得到文件名...都会触发

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926192707239.png" alt="image-20200926192707239" style="zoom: 80%;" />

##### 系统调用号

每个system call都会有对应的系统调用号(number)，不同操作系统上各不相同，内核查看系统调用号，查表并调用对应的程序即可

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926195307398.png" alt="image-20200926195307398" style="zoom:67%;" />

##### 参数传递的方式

除了系统调用号，还可以传递路径名、文件打开的模式等信息，也就是参数传递(parameter passing)，有以下三种方式：

- **Register**：通过寄存器传递，要求参数必须是整型或指针形式
- **Block**：通过block来传参，通常用于传递比较长的参数，比如通过把buffer放到Block里，buffer的地址放到Register或Stack里来传递buffer里的数据
- **Stack**：通过栈来传参

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926195937006.png" alt="image-20200926195937006" style="zoom:67%;" />

##### 特殊的系统调用：ioctl

ioctl(io control)是linux中万能的系统调用，由于system call大多是设备相关的，而像intel、amd这些不同的厂商，即使是相同的设备调用方式也不同，因此对所有的设备分别写system call是不现实的

system call所完成的功能大多数操作系统内核中比较通用的东西，很少去做特定设备相关的内容，当有这方面的需求时，就需要有这样一个万能的system call，它的具体功能是由request这个参数来决定

操作系统的内核只需要识别成fd对应的设备，再把request丢给对应设备的驱动处理即可，而不需要真正识别成request里的具体内容

优点：灵活

缺点：驱动由设备硬件厂商提供，容易出现安全漏洞，可能会导致用户态通过ioctl提权

~~~c
#include <sys/ioctl.h>
// fd为操作设备的描述符，request为具体的操作
int ioctl(int fd, unsigned long request, ...);
~~~

##### 小结

- 系统调用的目的：用户态和内核态打交道的途径
- API、System call与用户态程序、内核之间的关系
- 系统调用参数传递有哪几种方式
- 通过software trap实现用户态到内核态的转变过程

##### os structure

MS-DOS：没有任何隔离

FreeBSD：相对比较好的隔离

#### Linkers and Loaders

##### linker and loader

程序的链接、加载和运行，链接分为静态链接和动态链接，链接的方式不同，程序的加载方式也不同

**链接器(linker)**：把自己写的程序和第三方库连接在一起，即将多个`*.c`文件编译生成的`*.o`文件全部链接成一个可执行文件

**加载器(loader)**：当程序执行的时候，如何把它从磁盘上加载到内存里，解析动态库中，比如libc里的printf函数到底在哪

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926204449862.png" alt="image-20200926204449862" style="zoom:80%;" />

具体代码举例：

~~~c
// 文件1
#include <stdio.h>
extern int f (int x);
int i = 2;
char format[] = "f (%d) = %d\n";
int main(int argc, char const*argv[])
{
    int j;
    j = f(i);
    printf(format, i, j);
    return 0;
}

// 文件2
int f(int x) 
{
    if(x <= 1) 
        return x;
    return x - 1;
}
~~~

##### static linking

静态链接

下图是编译完成尚未进行链接的汇编代码

整个程序中有两个函数调用，`printf()`和`f()`，在下图中的汇编代码中利用跳转指令`bl`来实现

仔细看可以发现，下图中函数调用的地方，跳转地址都为0，这些地址将由具体链接的时候填充完成

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926205115087.png" alt="image-20200926205115087" style="zoom:80%;" />

静态链接生成的可执行文件都是比较大的，因为最后生成的可执行文件是自包含的，它在运行的时候不会再依赖于系统中的任何动态库了

最终生成的可执行文件如下所示，可以看到`printf`函数对应的地址变成了`b180`，即原先在libc里实现的printf函数及其依赖的所有代码都被直接copy到了可执行文件里，这也是文件大的原因

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926205822591.png" alt="image-20200926205822591" style="zoom:80%;" />

优点：自包含，不依赖于别人

缺点：生成的可执行文件大；相同的函数会在不同的可执行文件中生成多个拷贝，不同进程无法共享同一个库函数，造成资源浪费

##### dynamic linking

动态链接生成的可执行文件要远小于静态链接

首先对`f()`函数来说，是已经编译好的`.o`文件可以直接链接，而对`printf()`来说，它会链接到地址为`488`的地方，该地址上只有3条指令，做的事情是：**从内存中某个地址上取出一个值，并跳转到该值所表示的地址上继续执行**

经过计算可得`488`对应的地址为`2fe8`，是跳转表所在的地方，loader会把`printf()`真正的地址写到`2fe8`所对应的内存里

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200926210813098.png" alt="image-20200926210813098" style="zoom:80%;" />

加载器(loader)：

- 首先要把代码加载进内存里
- 然后解析库的依赖关系，发现该可执行文件依赖于libc的库，于是把`libc.so`也加载进内存里
- 此时就可以知道`libc`里的`printf()`函数在内存里的具体地址，就可以把该地址写到`2fe8`地址所对应的内存上，此后从`2fe8`地址上取得的值就是`printf()`函数的地址

这样做有缺点：如果可执行文件依赖了很多库函数，加载的时候就需要把每个库函数都解析出来并填入对应地址，会非常耗时，为了解决这个问题，会采用一种叫做延时绑定(lazy binding)的技术

#### os structure

##### MS-DOS

没有任何权限和隔离

##### UNIX

**整体内核**，把操作系统最关键的东西都放进内核里，很难将其中的某些功能部件剥离开

- 优点：性能好
- 缺点：内核态放了太多东西，结构复杂，扩展性差，一旦内核中的一小部分出了问题就会影响到整个内核(同一地址空间)，容错性不好，容易出bug

##### Microkernel

**微内核架构**，基本思想是把尽可能多的东西从内核态迁移到用户态

优点：

- 内核态的代码size减小，bug率降低，更可靠、更安全
- 某个组件出故障并不会影响到内核态整体和其他部件
- 扩展内核比较方便
- port内核到新架构比较容易

缺点：

- 原来在内核态通过函数调用(function call)就可以解决的事情，现在只能通过进程与进程之间的通讯才能完成，以用户态程序读取文件为例：
    - 整体内核：应用程序通过system call去操控file system，然后file system会通过device driver去操作磁盘的外设，注意此时file system和device driver都在内核里，只需要通过function call调用即可
    - 微内核：此时file system和device driver都在内核外(用户态)，如下图所示，这意味着，用户程序和file system和device driver之间的传递消息必须要通过内核帮忙来实现，整个流程就是用户程序->内核态传递消息->file system->内核态传递消息->device driver
    - 频繁的消息传递导致了微内核的效率低下

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200927095720738.png" alt="image-20200927095720738" style="zoom: 80%;" />

##### Kernel Moudles

整体内核为了增加扩展性，引入了**内核模块**(Kernel Modules)的概念，即linux内核在运行的时候，在不改变本身代码的情况下加载内核模块，内核模块可以使用linux内核提供的API接口做事情，这样就可以针对不同的硬件加载相应的内核模块，而不需要重新编译操作系统才能支持新的硬件

##### Exokernel

在传统操作系统中，只有特定权限的程序和内核可以操作系统资源，而用户程序只能面对抽象层，但实际上不同的应用程序对资源的需求是各不相同的，外内核的思想是把内核尽可能的做薄，只保留基本功能，而给予应用程序直接访问系统资源的接口

##### Comparison

四种操作系统的比较：

- DOS：所有操作系统的app和控制逻辑都在内核态实现，安全性不好
- UNIX：整体内核，把app放到用户态，跟resource manage相关的东西都放到内核态，两者通过system call来通信
- MicroKernel：微内核，把不一定需要在内核态做的事情放到用户态做，比如file system、driver等
- ExoKernel：外内核，把部分最简单的资源分配和逻辑放到用户态做

<img src="/media/gehao/Data/gehao/Documents/CS/Operation System/notes/img/image-20200927101956565.png" alt="image-20200927101956565" style="zoom: 80%;" />