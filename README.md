说明文档

成员：邱明阳 王溥纪 王思源

详细内容见PDF及源码

1 概述

  对于1000000以内素数的查找和显示，本组采用埃拉托色尼筛法，该筛法需使用RAM存储素数。其中，我们使用的IP核是 Vivado中自带的 Block Memory Generator，其具体配置见PDF附录。我们调用了simple并实现了四个模式下的素数输出，效果符合要求。虽然本代码未使用除法模块，但我们也研究并设计出了能够高效使用的流水线除法器。

2 代码解析

  代码含三个重要部分：底层优化部分、素数算法部分和RAM读写、数字显示部分。PDF中含有对源码的详细解析。（完整代码另见源码）

3 难点分析

3.1 时序分析混乱

  在我们最开始写各个模块时，我们偏向于设置大量的寄存器，在always块中做非阻塞赋值，这往往意味着always语块中会存在大量的条件判断语句。一旦这些条件间存在交集，便会出现寄存器重复赋值的现象。而如果条件考虑有缺失，代码在板上实际运行时便很可能陷入停滞。
最关键的是，寄存器的非阻塞赋值意味着赋值是没有顺序的，而我们在自己推演波形时，有时会忽略这一点，导致某个波形提前或推后一周期，从而使整个时序分析混乱，实际运行结果与预期不相符。

3.2 模块间关系不清晰

  由于每个模块都分工给不同的人来写，即使我们提前进行了整体架构的分析，并说明了每个模块需要的输入和输出，但是在实际写好后，仍然会出现模块间不协调的情况。这常常表现为模块在错误的时间给出了错误的数据。除了少数语法错误，我们大量的debug任务都集中在对模块间时序的协调上。

3.3 Debug难以准确找到实际问题

  由于Vivado的报错比较笼统抽象，导致我们在知道存在错误后难以正确的改错。而且即使是编译时未出现错误，在实际运行时也有可能出现错误，此时我们更是无法准确知道错误，只能反复研究运行逻辑，复查代码。这样的Debug效率是非常低的。

3.4 RAM读写存在难度

  我们认为几乎所有的素数算法都需要用到已算出的素数，而这些素数需要RAM来存储。值得提到的是，RAM的数据写入虽然是即时的，但是读取却会延迟两个周期，所以在涉及到RAM中数据读取时需要考虑数据传出的延迟，否则代码就会出现故障无法顺利运行。

4 心得体会

4.1 加强基础知识的储备

  事实上，过去的Verilog代码作业，我们习惯于在课堂PPT上寻找相似代码，再稍作修改，然后根据仿真波形图不断Debug得到正确代码。这使得我们对Verilog的很多基础语法缺乏对本质的理解，所以在实现这样的更加复杂的大型代码时，我们很容易犯大量的低级语法错误。对reg、wire型变量的理解，对阻塞赋值、非阻塞赋值的理解，对always块，generate for块的理解，对模块实例化的理解等等……这些都是我们在写这个代码时才逐渐深化的。

4.2 厘清思路、注重协作

  该代码的完成离不开所有组员的分工和合作，所以无论是在讨论思路、设计代码还是修改代码时，都应当注重成员间的信息交流。虽然每个人的任务相对独立，但也要一定程度地理解他人所写模块。互相理解也是个互查互促的过程。这样才能更加高效地完成任务。同时，写代码前一定要做充足的思考，比如对算法优化的可能性分析，对时间复杂度的分析等等。做好详尽的准备有利于任务的顺利推进。

5 致谢

  本次大作业的顺利完成，离不开每位组员的通力协作，更离不开平时宋威老师的讲解和马浩助教的指导。这次大作业极大地锻炼了我们的verilog代码的设计编写能力和FPGA的开发能力，为我们后续课程垒下了坚实的基础。

