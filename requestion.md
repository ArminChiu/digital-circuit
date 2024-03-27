FPGA和外设
FPGA

Xilinx Arty-7 系列 A35T，Xilinx第7代小型FPGA

官方文档：https://china.xilinx.com/content/dam/xilinx/support/documentation/data_sheets/ds180_7Series_Overview.pdf

具体型号：XC7A35T 封装：FGG484 速度：-2 

实验软件

使用Xilinx的Vivado设计工具

Vivado ML: Vivado v2021.1 (64-bit)
 
实验大作业

素数循环显示

利用4个按键，4个LED显示和6个7段数码管

4个按钮选择循环模式

按键1：递增，每秒变一次（上电之后的默认模式）

按键2：递减，每秒变一次

按键3：递增，最快速度

按键4：递减，最快速度

4个LED显示当前模式

6个七段数码管显示2到999999之间的素数

不可以提前将素数计算好存储在FPGA内，必须运行时计算