# MIPS-Five-stage-CPU


## Stage 7

### Requirements :

* 将 myCPU 里的存储管理机制更改为 TLB 映射方式。
* Lab7 第一阶段(2018 年 12 月 4 日检查),需要完成:
    * CPU 增加 TLBR、TLBWI、TLBP 指令。
    * CPU 增加 Index、EntryHi、EntryLo0、EntryLo1 、PageMask CP0 寄存器。
    * CPU 增加 32 项 TLB 结构,支持的页大小位 4KB。
    * 运行专用功能测试 tlb_func,要求通过前 7 项测试。
* Lab7 第二阶段(2018 年 12 月 11 日检查),需要完成:
    * CPU 增加 TLB 相关例外:Refill、Invalid、Modified。
    * 运行专用功能测试 tlb_func,要求全部通过,共 10 项测试。
* Lab7 第 一 、 二 阶 段 的 测 试 程 序 都 包 含 在 tlb_func 里 , 在 tlb_func/start.S 的 第 5 行 定 义 了 "#define TEST_TLB_EXCEPTION 0",表示是否测试 TLB 例外。
    * #define TEST_TLB_EXCEPTION 0:不测试 TLB 例外,tlb_func 共 7 个功能点测试,供第二阶段使用。
    * #define TEST_TLB_EXCEPTION 1:测试 TLB 例外,tlb_func 共 10 个功能点测试,供第三阶段使用。当前发布的 tlb_func 默认是"#define TEST_TLB_EXCEPTION 0",在进行增加 TLB 例外支持后,需设置为"#define TEST_TLB_EXCEPTION 1",之后重新编译。

### Instruction :

* 本次实验只需实现 TLBWI、TLBR、TLBP 指令。
    * TLBWI 指令是以 cp0 寄存器 Index 为索引,将 EntryHi、PageMask、EntryLo0、EntryLo1 写入到寻址到的 TLB 项中。
    * TLBR 指令则与 TLBWI 相反,是以 Index 为索引,读出寻址到的 TLB 项的值写入到 EntryHi、PageMask、EntryLo0、EntryLo1。显然测试 TLB 是否初始化完成也可以使用该指令。
    * TLBP 指令则是使用 EntryHi 里的 VPN2 和 ASID 去查找整个 TLB,看是否有某一 TLB 项可以翻译该虚拟地址。如果查找到则将该项 TLB 索引号写入到 cp0 寄存器 Index 中;如果没找到则将 Index 高位置 1,其他位任意值。显然该指令测试通过,表示 TLB 查找通路是没问题的。

## Stage 6

### Requirements :

* 补充完 PMON 源代码中被删除的 Cache 初始化、TLB 初始化、串口初始化部分,编译后在一个已完成的 SoC 设计上正常启动并成功装载和启动 Linux 内核。
* 要求刚下载完 bit 文件后,PMON 运行时打印的信息无“TLB init Error!!! ”和“cache init Error!!! ”。且能正确装载并启动 Linux 内核。

### Instruction :

* 本次实验基于我们提供的一个完整的 SoC,该 SoC 中集成了一个完备的带有 TLB 和 Cache 的双发射 32 位 CPU(以下简称 CPU232),并且集成了 SPI flash 控制器、串口(UART)控制器、网卡(MAC)控制器和内存(DDR3)控
制等。
* 本次实验内容为完善 PMON(类似于 BIOS 程序),PMON 是作为软件代码需要编译后烧写到 SPI flash 芯片中。
而硬件部分是直接提供该 SoC 使用 Vivado 生成的 bit 流文件,可直接烧写到开发板上,运行 SPI flash 上的 PMON
即可。故本次实验只涉及到 MIPS 汇编编程,且无法通过 Xsim 仿真进行调试,只能使用软件调试手段。

## Stage 5

### Requirements :

* 为 myCPU 增加 AXI 总线支持,完成功能测试,并支持运行一定的应用程序。本次实验分两周完成,第一周(2018 年 11 月 13 日检查),需要完成:
    * 完全带握手的类 SRAM 接口到 AXI 接口的转换桥 RTL 代码编写。
    * 通过简单的读写测试。
* 第二周(2018 年 11 月 20 日检查),需要完成:
    * CPU 顶层修改为 AXI 接口。CPU 对外只有一个 AXI 接口,需内部完成取指和数据访问的仲裁。
    * 集成到 SoC_AXI_Lite 系统中。
    * 完成功能测试。
    * 在 myCPU 上运行 lab3 的电子表程序,要求能实现相同功能。

## Stage 4

### Requirements :

* 为 myCPU 增加例外与中断支持,完成功能测试,并支持运行一定的应用程序。
* 本次实验分两周完成,第一周(2018 年 10 月 30 日检查),需要完成:
    * CPU 增加 MTC0、MFC0、ERET 指令。
    * CPU 增加 CP0 寄存器 STATUS、CAUSE、EPC。
    * CPU 增加 SYSCALL 指令,也就是增加 syscall 例外支持。
    * 运行功能测试通过。功能测试程序为 lab4_func_1,是在 lab2_func 的基础上增加第 69 个功能点测试,也就是 SYSCALL 例外测试。
* 第二周(2018 年 11 月 6 日检查),需要完成:
    * CPU 增加 BREAK 指令,也就是增加 break 例外支持,。
    * CPU 增加地址错、整数溢出、保留指令例外支持。
    * CPU 增加 CP0 寄存器 COUNT、COMPARE。
    * CPU 增加时钟中断支持,时钟中断要求固定绑定在硬件中断 5 号上,也就是 CAUSE 对应的 IP7 上。
    * CPU 增加 6 个硬件中断支持,编号为 0~5,对应 CAUSE 的 IP7~IP2。
    * CPU 增加 2 个软件中断支持,对应 CAUSE 的 IP1~IP0。
    * 完成 lab4_fun_2 功能测试。
    * 在 myCPU 上运行 lab3 的电子表程序,要求能实现相同功能。
    * 在 myCPU 上运行记忆游戏程序,要求能正确运行

### Instruction :

* 例外与中断实现说明
    * 本次实验共需实现系统调用、断点、地址错、整型溢出、保留指令例外,以及时钟中断、硬件中断、软件中断。
    * 关于这些例外与中断的详细描述,以及 CPU 处理机制、CP0 寄存器等请参见文档―A05_“体系结构研讨课” MIPS 指令系统规范"。关于系统控制寄存器的描述,属于 MIPS 架构的子集,是针对本课程实验整理得到的简化设计描述。请认真阅读该文档,避免运行功能测试时 trace 比对出错。

## Stage 3

### Requirements :

* 编译一段汇编程序,运行在 SoC_Lite 上,调用 Confreg 模块的数码管和按钮开关等外设,实现一个 12 /24 小时进制的电子表,并在实验板上予以演示。
* 该电子表的显示包含时、分、秒,采用实验箱开发板上的 4 组数码管显示,并通过板上的矩阵键盘完成电子表的设置功能。具体要求是:
    * 电子表具有一个暂停/启动键,具有时、分、秒设置键。
    * 电子表复位结束后从 0 时 0 分 0 秒开始计时,按下暂停/启动键一次则计时暂停进入设置模式,此时可以通过时、分、秒的设置键修改时、分、秒的值,再次按下暂停/启动键则推出设置模式并从设置好的时间开始继续计时。
    * 时、分、秒设置键的设置方式是每按下一次,对应的时、分、秒值循环加 1,按住不放则按照一定频率不停地循环加 1 直至按键松开。
    * 时、分、秒设置键仅在设置模式下操作才有效果。
    * 矩阵键盘上非设置键被按下,应当不影响电子表的精确计时。
    * 采用硬件中断+时钟中断完成本次实验的满分是 100%,采样硬件中断或时钟中断完成本次实验的满分是95%,所有功能都是采用轮询完成的本次实验的满分是 80%。
    * 时间有余的可以考虑实现闹铃功能,但这不在本次实验要求范围内,也不承诺有本课程最终分数上的加分。


## Stage 2

### Requirements :

* 设计一款静态 5 级流水简单 MIPS CPU。
* 本次实验分三个阶段完成,时间跨度三周课时(9 月 25 号—10 月 16 号,中间一周国庆放假)。
* 本次实验要求延续 lab1 实验中的以下要求:
    * CPU 复位从虚拟地址 0xbfc00000 处取指。
    * CPU 虚实地址转换采用:虚即是实。
    * CPU 对外访存接口为取指、数据访问分开的同步 SRAM 接口。
    * CPU 只实现一个操作模式:核心模式,不要求实现其他操作模式。
    * 不要求支持例外和中断。
    * CPU 顶层连出写回级的 debug 信号,以供验证平台使用。
* 整个实验中,最后要求实现 MIPS I 指令集,参考文档―A05_“体系结构研讨课”MIPS 指令系统规范",除了 ERET(非 MIPS I)、MTC0、MFC0、BREAK、SYSCALL 指令,其余指令均要求实现,共 56 条指令。
* 本次实验三个阶段,每个分阶段设有底线任务,并对应一段功能测试程序,要求在验证平台上运行功能
测试通过。四个阶段的功能测试程序为:lab2_func_1、lab2_func_2、lab2_func_3,将会在实验过程中陆
续发布。
* 第一阶段(9 月 25 号检查),要求至少完成如下设计:
    * 至少支持 lab1 要求的 19 条机器指令:**LUI、ADDU、ADDIU、SUBU、SLT、SLTU、AND、OR、XOR、NOR、SLL、SRL、SRA、LW、SW、BEQ、BNE、JAL、JR**。
    * CPU 微结构为静态 5 级流水。
    * 要求实现 MIPS 架构的延迟槽技术,延迟槽不再设定为 NOP 指令,可能是任意指令。
    * 可以不用考虑数据相关,第一阶段提供的测试程序 func_1 不存在指令间的数据相关。
    * 控制相关由分支指令造成,通过延迟槽技术可以完美解决。
    * 结构相关即某一级流水停顿了,会阻塞上游的流水级。
    * 要求仿真和上板运行 lab2_func_1 通过。
    * 提交第一阶段的实验报告和 lab2-1 作品。
* 第二阶段(10 月 9 号检查),在第一阶段的基础上,要求至少完成如下设计:
    * 至少新增如下 19 条机器指令:**ADD、ADDI、SUB、SLTI、SLTIU、ANDI、ORI、XORI、SLLV、SRAV、SRLV、DIV、DIVU、MULT、MULTU、MFHI、MFLO、MTHI、MTLO**。
    * 要求考虑数据相关,func_2 存在指令间的数据相关。
    * 要求数据相关采用前递处理。
    * 要求乘法采用 booth 算法+华莱士、除法采用迭代算法。
    * 要求仿真和上板运行 lab2_func_2 通过。
    * 提交第二阶段的实验报告和 lab2-2 作品。
* 第三阶段(10 月 16 号检查),在第二阶段的基础上,要求至少完成如下设计:
    * 至少新增如下 18 条指令: **J、BGEZ、BGTZ、BLEZ、BLTZ、BLTZAL、BGEZAL、JALR、LB、LBU、LH、LHU、LWL、LWR、SB、SH、SWL、SWR**。
    * 要求仿真和上板运行 lab2_func_3 通过。
    * 要求仿真和上板运行性能测试程序 Coremark 和 dhrystone 通过。
    * 要求计算自实现 myCPU 的性能。
    * 推荐尽量优化 myCPU 的性能。
    * 提交第三阶段的实验报告和 lab2-3 作品。

## Stage 1

### Requirements :

* 迁移组成原理研讨课上完成的多周期 CPU 设计到本学期实验平台上。
* 要求多周期 CPU 至少支持以下 19 条机器指令:**LUI、ADDU、ADDIU、SUBU、SLT、SLTU、AND、OR、XOR、NOR、SLL、SRL、SRA、LW、SW、BEQ、BNE、JAL、JR**。
* 要求多周期 CPU 对外访存接口为取指、数据访问分开的两个 SRAM 接口,且 SRAM 接口是同步读、同
步写的。
* 要求多周期 CPU 顶层连出部分 debug 信号,以供验证平台使用。
* 要求多周期 CPU 复位从虚拟地址 0xbfc00000 处取指。
* 要求多周期 CPU 虚实地址转换采用:虚即是实,也就是转换过程不需要对虚拟地址作变换。
* 要求多周期 CPU 将每条指令对应的 PC 每个周期都带下去,一直带到写回级(最后一级),这个信息,暂时 mycpu 里不会用到,但验证平台会使用到。
* 要求实现 MIPS 架构的延迟槽技术,可以认为软件在延迟槽放置的永远为 NOP 指令。
* 要求多周期 CPU 只实现一个操作模式:核心模式,不要求实现其他操作模式。
* 不要求支持例外和中断。
* 不要求实现任何系统控制寄存器。
* 要求将多周期 CPU 嵌入到提供的一个简化系统 SoC_lite 上。完成仿真和上板功能验证。













