# c/c++编译、make、cmake

#### c/c++编译

`gcc`和`g++`分别是gnu的c & c++编译器，gcc/g++在执行编译工作的时候，总共需要4步

1. 预处理,生成`.i`的文件[预处理器cpp]

    ~~~bash
    # 生成main.i预处理文件
    g++ -E main.cpp -o main.i
    gcc -E main.c -o main.i
    ~~~

2. 将预处理后的文件转换成汇编语言,生成文件`.s`[编译器egcs]

    ~~~bash
    # 生成main.s汇编代码
    g++ -S main.cpp
    gcc -S main.c
    ~~~

3. 由汇编变为目标代码(机器代码)生成`.o`的文件[汇编器as]

    ~~~bash
    # 生成main.o二进制目标代码文件
    g++ -c main.cpp
    gcc -c main.c
    ~~~

4. 连接目标代码,生成可执行程序[链接器ld]

    ~~~bash
    # 将多个.o文件链接生成main可执行文件
    g++ -o main main.o *.o
    gcc -o main main.o *.o
    
    # 或者直接将源代码生成main可执行文件
    g++ -o main main.cpp *.cpp
    gcc -o main main.c *.c
    
    # 如果不指定名称main，则默认生成a.out可执行文件
    ~~~

#### make

##### 原始方法：

- 冒号`:`，用于标识目标文件及其依赖文件，叫做**依赖关系**
- 以`tab`开头的是命令，用于将部分依赖文件(不包括`.h`)生成目标文件，叫做**执行命令**

~~~bash
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o

edit : $(objects) # 第一行的依赖左侧默认为最终生成可执行对象文件，即edit
    gcc -o edit $(objects)

main.o : main.c defs.h
    gcc -c main.c
kbd.o : kbd.c defs.h command.h
    gcc -c kbd.c
command.o : command.c defs.h command.h
    gcc -c command.c
display.o : display.c defs.h buffer.h
    gcc -c display.c
insert.o : insert.c defs.h buffer.h
    gcc -c insert.c
search.o : search.c defs.h buffer.h
    gcc -c search.c
files.o : files.c defs.h buffer.h command.h
    gcc -c files.c
utils.o : utils.c defs.h
    gcc -c utils.c
clean :
    rm edit $(objects)
~~~

##### 简便方法：

make的自动推导：只要make看到一个 `.o` 文件，它就会自动的把 `.c` 文件加在依赖关系中，如果make找到一个 `whatever.o` ，那么 `whatever.c` 就会是 `whatever.o` 的依赖文件，并且 `cc -c whatever.c` 也会被推导出来，于是，我们的makefile再也不用写得这么复杂

下面的例子是比较简单的书写形式

~~~bash
# 设置变量
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o

edit : $(objects) # 依赖
    gcc -o edit $(objects) # 生成命令，开头必须是tab

main.o : defs.h # 依赖中隐藏了.c
# 并且隐藏了生成命令 g++ -c main.c
kbd.o : defs.h command.h
command.o : defs.h command.h
display.o : defs.h buffer.h
insert.o : defs.h buffer.h
search.o : defs.h buffer.h
files.o : defs.h buffer.h command.h
utils.o : defs.h

.PHONY : clean
clean :
    rm edit $(objects)
~~~

##### make进阶：通配符和函数

参考[文章](https://www.cnblogs.com/aaronLinux/p/7077016.html)

**变量**，适用于已经规定好依赖关系后的**执行命令**：

- `$@`: 表示目标文件，用法：
    - `gcc -o $@ $(obj)`或`gcc -o $@ $^`：将所有中间目标文件( \$(obj) or \$^ )转化为最终的可执行目标文件(\$@)
    - `gcc -o $@ -c $<`：将依赖文件(\$<)转化为中间目标文件(\$@)

- `$^`: 表示所有依赖文件，用法：
    - `gcc -o $@ $^` ：用所有依赖文件\*.o链接成目的文件exe

- `$<`:表示第一个依赖文件，用法：
    - `gcc -o $@ -c $<` ：每个依赖文件.c生成一个目的文件.o

**函数**(假设变量`SRC=./src  OBJ=./obj`)，生成的文件一般用于**依赖关系**

- `wildcard`: 是扩展通配符函数，功能寻找并展开指定路径下所有符合描述的文件名，不同文件名之间用空格间隔，比如列出`.`和`src/`目录下的所有`.c`文件，并存放到变量`SOURCE`：`SOURCE = $(wildcard *.c ${SRC}/*.c)`

- `patsubst`: 是匹配替换函数，格式为`patsubst(原格式，目标替换格式，需要被匹配的文件名)`，比如用`src\`下的\*.c替换成对应的`obj/`目录下的\*.o文件，并存放到变量`OBJECT`：`OBJECT = $(patsubst %.c, ${OBJ}/%.o, $(notdir $(SOURCE)))`

- `notdir`: 是去除路径函数，在上面patsubst函数中已经被使用过，即去掉路径名、只留文件名，比如得到的`src/main.c`变为`main.c`

这个时候实际上已经有了最终可执行文件的依赖中间目标文件`OBJECT`，并且已经规定了它们生成的目录为`./obj`下

~~~bash
TARGET = ./bin/main
# 当依赖关系中已经给出具体的对象集合时，在执行命令中就可以用$@表示最终可执行目标文件$(TARGET)，$^表示中间目标文件$(OBJECT)
$(TARGET) : $(OBJECT) # 依赖关系
	gcc $(CFLAGS) -o $@ $^ # 执行命令
~~~

并且规定`./obj`目录下的中间目标文件.o与`./src`目录下的源文件.c之间的关系：

~~~bash
$(OBJ)/%.o : $(SRC)/%.c # %是通配符，表示两目录下的文件一一对应 
	gcc $(CFLAGS) -o $@ -c $<  # $@指%.o，$<指$.c
~~~

##### CFLAGS参数

注意，上面出现的`CFLAGS`，是为了弥补依赖关系中只有.c而没有.h导致编译时无法找到库文件的问题，`CFLAGS`一般为gcc/g++的参数，如果是g++一般会加上-std=c++11：

~~~bash
INC = ./include # INC是所有.h文件所在路径
CFLAGS = -g -Wall -std=c++11 -I${INC}
~~~

举例：如果没有\$(CFLAGS)，那么得在main.c文件中将包含的头文件由#include "fun.h"改成#include "../include/fun.h"，即对应了：\$(CFLAGS) + #include "fun.h"

由此可见，在程序main.c中没有指明fun.h的具体位置，就得靠\$(CFLAGS)中的`-I${INC}`指定路径去寻找；或者在程序中使用\#include "../include/fun.h"直接指明所需头文件的位置，这样就不用$(CFLAGS)去寻找

##### makefile模板

总结前面的内容，提供这样一份模板：

~~~bash
# 把所有路径都保存到变量里，方便修改
BIN = ./bin # 生成最终可执行文件的目录
SRC = ./src # c/cpp源文件目录
INC = ./include # .h文件目录
OBJ = ./obj # 生成的中间文件存放目录

NEWDIR = new_dir

# 将./src目录和./src/new_dir下所有*.c文件名称按空格隔开全部放进变量SOURCE中
SOURCE = $(wildcard ${SRC}/*.c ${SRC}/${NEWDIR}/*.c)
# 每个.c文件都建立对应./obj目录下的.o文件名称，并放进变量OBJECT中，用于后续的依赖文件和生成
OBJECT = $(patsubst %.c, ${OBJ}/%.o, $(notdir ${SOURCE})) # 此时.o还未生成

CC = gcc # 把gcc作为变量，方便后续编译器的替换
CFLAGS = -g -Wall -std=c89 -I${INC} # CFLAGS用于存放编译器的参数，包括.h的寻找路径

# 最终可执行文件叫做main，存放到变量TARGET中
TARGET = main
BIN_TARGET = ${BIN}/${TARGET}

# 由于makefile只能有一个目标，所以可以构造一个没有规则的终极目标all，并以这两个可执行文件作为依赖，因此分别执行这两个标签下的内容
all : CHECKDIR ${BIN_TARGET} # 这句话是为了执行CHECKDIR和${BIN_TARGET}这两个依赖

# 如果当前目录下没有bin和obj文件夹，则进行创建
CHECKDIR:
	mkdir -p ${BIN} ${OBJ} # mkdir -p 目录名: 对已存在的目录不做处理 如果目录不存在就进行创建

# 建立最终可执行文件和中间目标文件的依赖关系和执行命令
${BIN_TARGET} : ${OBJECT}
	${CC} ${CFLAGS} -o $@ $^
	
# 建立起中间文件.o和源文件.c的依赖关系和执行命令，注意多文件结构每个文件都要写个依赖
# ./obj下的部分.o与./src下的.c的依赖
${OBJ}/%.o : ${SRC}/%.c # 这里的%可以被理解成"每一个"
	${CC} ${CFLAGS} -o $@ -c $<
	
# ./obj下剩余.o与./src/new_dir下的.c的依赖
${OBJ}/%.o : ${SRC}/${NEWDIR}/%.c
	${CC} ${CFLAGS} -o $@ -c $<
# 注：这里的.o文件是之前OBJECT里定义好的文件路径名称，还未创建，但是在这里已经与对应的.c建立起了依赖关系，因此一旦make发现.o未创建，就可以根据.c立即生成到已经定好的.o文件路径上

.PHONY : clean
clean:
	rm -rf ${OBJ}/*.o ${BIN_TARGET}
~~~

##### make实例

###### 文件树

首先通过`tree`查看文件树(需要通过sudo apt install tree安装)

- 初始文件树

    ~~~bash
    .
    ├── include
    │   └── mathfunc.h
    ├── makefile
    └── src
        ├── main.cpp
        └── mathfunc
            └── mathfunc.cpp
    
    3 directories, 4 files
    ~~~

- 执行make后的文件树

    ~~~bash
    .
    ├── bin
    │   └── output
    ├── include
    │   └── mathfunc.h
    ├── makefile
    ├── obj
    │   ├── main.o
    │   └── mathfunc.o
    └── src
        ├── main.cpp
        └── mathfunc
            └── mathfunc.cpp

    5 directories, 7 files
    ~~~

###### 相关代码

- `main.cpp`：    

    ```cpp
    #include <stdio.h>
    #include <stdlib.h>
    #include "mathfunc.h"
    int main(int argc, char *argv[])
    {
        if (argc < 3){
            printf("Usage: %s base exponent \n", argv[0]);
            return 1;
        }
        double base = atof(argv[1]);
        int exponent = atoi(argv[2]);
        double result = power(base, exponent);
        printf("%g ^ %d is %g\n", base, exponent, result);
        return 0;
    }
    ```

- `mathfunc.cpp`：

    ~~~cpp
    #include "mathfunc.h"
    
    double power(double base, int exponent)
    {
        int result = base;
        int i;
        
        if (exponent == 0) {
            return 1;
        }
        
        for(i = 1; i < exponent; ++i){
            result = result * base;
        }
    
        return result;
    }
    ~~~


- `mathfunc.h`：

    ~~~cpp
    #ifndef __MATHFUNC_H__
    #define __MATHFUNC_H__
    extern double power(double base, int exponent);
    #endif
    ~~~

###### makefile文件

~~~bash
BIN = ./bin
SRC = ./src
INC = ./include
OBJ = ./obj

MATH = mathfunc

SOURCE = $(wildcard ${SRC}/*.cpp ${SRC}/${MATH}/*.cpp)
OBJECT = $(patsubst %.cpp, ${OBJ}/%.o, $(notdir ${SOURCE}))

TARGET = output
BIN_TARGET = ${BIN}/${TARGET}

CC = g++
CFLAGS = -g -Wall -std=c++11 -I${INC}

all : CHECKDIR ${BIN_TARGET}

CHECKDIR:
	mkdir -p ${BIN} ${OBJ}

${BIN_TARGET} : ${OBJECT}
	${CC} ${CFLAGS} -o $@ $^

${OBJ}/%.o : ${SRC}/%.cpp
	${CC} ${CFLAGS} -o $@ -c $<

${OBJ}/%.o : ${SRC}/${MATH}/%.cpp
	${CC} ${CFLAGS} -o $@ -c $<

.PHONY : clean
clean:
	rm -rf ${BIN_TARGET} ${OBJ}/*.o 
~~~

##### makefile多目录层级调用

前面的例子是用一个makefile完成多文件编译，但当工程特别复杂时，这么做也不是很合理；因此我们需要在每个目录下一个写一个相对独立的makefile，再用总目录下的makefile去调用各子目录下的makefile(通过`make -C `实现)，以达到相互配合编译的效果

具体实现可参考[bootloader](./bootloader)，它仿照linux编译的基本结构，基于makefile和riscv实现了机器启动时对硬件的初始化，并从汇编跳转到`main.c`显示`hello riscv`的功能，编译后的结构如下：

~~~bash
.
├── arch
│   └── riscv
│       ├── boot
│       │   └── Image
│       ├── include
│       ├── kernel
│       │   ├── head.S
│       │   ├── Makefile
│       │   └── vmlinux.lds
│       └── Makefile
├── include
│   └── test.h
├── init
│   ├── main.c
│   ├── Makefile
│   └── test.c
├── Makefile
├── obj
│   ├── head.o
│   ├── main.o
│   └── test.o
├── System.map
└── vmlinux
~~~

#### cmake

cmake是对make更高层次的抽象，它可以通过简单的命令根据当前环境自动转化为makefile文件，从而实现了跨平台的特性

[cmake参考文章](https://www.hahack.com/codes/cmake/)

##### 文件结构

~~~bash
- cmake_test/
	- build/
	- CMakeLists.txt
	- src/
		- main.cpp
		- mathfunc/
			- mathfunc.cpp
			- mathfunc.h
			- CMakeLists.txt
~~~

##### 第一级的`CMakeLists.txt`：

~~~cmake
# cmake最低版本要求
cmake_minimum_required(VERSION 3.5.1)

# 工程名(顶层文件名)
project(cmake_test)

# 把源代码文件所在目录赋值给变量
aux_source_directory(src DIR)

# 将目录所在的源代码文件合成为一个叫做output的可执行文件
add_executable(output ${DIR})

# 添加子目录，告诉cmake还有一级的cmakelists.txt需要解析
add_subdirectory(src/mathfunc)

# 添加该子目录下已经生成好的链接库mathfunc_o，并链接到可执行文件output
target_link_libraries(output mathfunc_o)
~~~

##### 第二级的`CMakeLists.txt`：

~~~cmake
# 把当前目录赋值给变量DIR_2
aux_source_directory(. DIR_2)

# 生成链接库
add_library(mathfunc_o ${DIR_2})
~~~

##### 执行`cmake`和`make`：

~~~bash
# 打开build目录，执行以下操作，cmake后面跟的参数是CMakeLists.txt所在目录，之所以放在build下执行是为了让生成文件都放到build目录中，避免文件复杂混乱
cmake ..
make
./output param1 param2 ...
~~~

##### 代码：

- `main.cpp`

    ~~~cpp
    #include <stdio.h>
    #include <stdlib.h>
    #include "mathfunc/mathfunc.h"

    int main(int argc, char *argv[])
    {
        if (argc < 3){
            printf("Usage: %s base exponent \n", argv[0]);
            return 1;
        }
        double base = atof(argv[1]);
        int exponent = atoi(argv[2]);
        double result = power(base, exponent);
        printf("%g ^ %d is %g\n", base, exponent, result);
        return 0;
    }

    ~~~

- `mathfunc.cpp`

    ~~~cpp
    #include "mathfunc.h"

    double power(double base, int exponent)
    {
        int result = base;
        int i;

        if (exponent == 0) {
            return 1;
        }

        for(i = 1; i < exponent; ++i){
            result = result * base;
        }

        return result;
    }
    ~~~

- `mathfunc.h`

    ~~~cpp
    #ifndef __MATHFUNC_H__
    #define __MATHFUNC_H__

    extern double power(double base, int exponent);

    #endif
    ~~~

