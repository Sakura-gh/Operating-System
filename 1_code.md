# Sample Code

#### cpu.c

##### 功能

while循环，不停打印用户输入的string

##### 代码

~~~c
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <assert.h>
#include "common.h"

// 功能: while循环，不停打印用户输入的string
int
main(int argc, char *argv[])
{
    if(argc != 2) {
        fprintf(stderr, "usage: cpu <string>\n");
        exit(1);
    }

    char *str = argv[1];
    while(1) {
        Spin(1);
        printf("%s\n", str);
    }

    return 0;
}
~~~

##### 编译

~~~bash
gcc cpu.c -o cpu -lpthread
~~~

##### 运行

~~~c
./cpu a & ./cpu b
~~~

##### 结果

不断分行输出a b a b a b...，会让你感觉每个进程都有CPU资源在运行，这就是**CPU资源的虚拟化**

退出进程的方式：先`ctrl c`退出b的进程，再使用`ps`查看a的`pid`，并使用`kill pid`的方式杀死a的进程

#### mem.c

##### 功能

申请分配一块内存，并且把pid和申请到的首地址打印出来；然后循环遍历申请空间，往申请到的内存里写东西(+1)，并且和pid一并打印出来

##### 代码

~~~c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

// 功能:申请分配一块内存，并且把pid和地址打印出来；然后循环，往申请到的内存里写东西(+1)，并且打印出来
int
main(int argc, char *argv[])
{
    int *p = malloc(sizeof(int));
    assert(p != NULL);
    printf("(%d) memory address of p: %08x\n", getpid(), (unsigned) p);

    *p = 0;
    while(1) {
        Spin(1);
        *p = *p + 1;
        printf("(%d) p: %d\n", getpid(), *p);
    }

    return 0;
}
~~~

##### 编译

~~~bash
gcc mem.c -o mem -lpthread
~~~

##### 运行

~~~bash
./mem
~~~

##### 结果

~~~bash
(8582) memory address of p: 00730010
(8582) p: 1
(8582) p: 2
(8582) p: 3
(8582) p: 4
(8582) p: 5
...
~~~

按`ctrl c`退出进程

注意，每次进程p的虚拟地址都是随机的

#### threads.c

##### 功能

一个进程里有两个线程，每个线程都会循环很多次，每次循环使全局变量counter++，最终输出counter的值

##### 代码

~~~c
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

// 功能: 一个进程里有两个线程，每个线程都会循环很多次，每次循环使全局变量counter++; 如果每个线程各循环1000次，我们希望counter的值为2000，但实际上并不是这样
volatile int counter = 0;
int loops;

void *worker(void *arg) {
    int i;
    for(i = 0; i < loops; i++) {
        counter++;
    }
    return NULL;
}

int
main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "usage: threads <value>\n");
        exit(1);
    }

    loops = atoi(argv[1]);
    pthread_t p1, p2;
    printf("Initial value : %d\n", counter);

    Pthread_create(&p1, NULL, worker, NULL);
    Pthread_create(&p2, NULL, worker, NULL);
    Pthread_join(p1, NULL);
    Pthread_join(p2, NULL);
    printf("Final value : %d\n", counter);
    return 0;
}
~~~

##### 编译

~~~bash
gcc threads.c -o threads -lpthread
~~~

##### 运行

~~~bash
./threads 10
Initial value : 0
Final value : 20

./threads 100
Initial value : 0
Final value : 200

./threads 1000
Initial value : 0
Final value : 2000

./threads 10000
Initial value : 0
Final value : 19893

./threads 100000
Initial value : 0
Final value : 124952

./threads 1000000
Initial value : 0
Final value : 1085143
~~~

如果每个线程各循环10000次，我们希望counter的值为20000，但实际上并不是这样

这是因为如果线程需要循环的次数很少，单个线程很快就能够完整运行结束；但如果线程需要循环的次数很多，这时两个线程被CPU调度，在C语言的层面，counter执行的是++运算，但在汇编层面至少需要3条指令：

- 把counter的value取到某个register里
- 使register的值+1
- 再把register写回到原先的地址

注意到，CPU执行的是指令，很有可能线程1刚把counter value(假设为4)取到register的时候，还没来得及加1就已经发生调度了，此时线程2运行，就算它很顺利地把3条指令给跑完了(取值4，加1得5，存5到内存)，当线程1得到CPU调度资源时，它会从之前中断的地方继续往下执行，此时register里存的值不是由线程2已经更新完的5，而是之前残留的4，4+1=5再被存到内存里，这就出现了同步的问题

当循环的次数越多，发生这个问题的概率就越大