module top(
    input clk,
    input rstn,
    output [3:0] led,
    input [3:0] key,
    output [5:0] seg_sel,
    output [7:0] seg_dig
);

    wire [3:0] key_out;
    wire [3:0] pulse;
    wire [31:0] timer;
    wire [3:0] key_state;
    wire [19:0] num;
    wire [19:0] sum;
    wire [19:0] printtoscreen;
    edge_detect edge_detect_inst (.clk(clk), .rstn(rstn), .key_out(key_out), .pulse(pulse)); // 对应key[0]的边沿检测
    key_debounce key_debounce_inst (.clk(clk), .rstn(rstn), .key(key), .key_out(key_out));
    pulse_timer pulse_timer_inst (.clk(clk), .rstn(rstn), .pulse(pulse), .timer(timer), .key_state(key_state));
    find find_inst (.clk(clk), .rstn(rstn), .num(num), .sum(sum));
    //wire define
    wire ram_wr_en ; //端口 A 使能
    wire ram_wr_we ; //ram 端口 A 写使能
    wire ram_rd_en ; //端口 B 使能
    wire [19:0] ram_wr_addr; //ram 写地址
    wire ram_wr_data; //ram 写数据
    wire [19:0] ram_rd_addr; //ram 读地址
    wire ram_rd_data; //ram 读数据
    //RAM 写模块
    ram_wr ram_wr_inst(
        .clk            (clk       ),
        .rstn           (rstn     ),
        .sum(sum),
        .ram_wr_en      (ram_wr_en     ),
        .ram_wr_we      (ram_wr_we     ),
        .ram_wr_addr    (ram_wr_addr   ),
        .ram_wr_data    (ram_wr_data   )
    );

    //简单双端口 RAM
    ram_ip ram_ip_inst (
        .clka      (clk       ), // input wire clka
        .ena       (ram_wr_en     ), // input wire ena
        .wea       (ram_wr_we     ),
        .addra     (ram_wr_addr   ),
        .dina      (ram_wr_data   ),
        .clkb      (clk       ), // input wire clkb
        .enb       (ram_rd_en     ), // input wire enb
        .addrb     (ram_rd_addr   ),
        .doutb     (ram_rd_data   )
    );

    //RAM 读模块 
    ram_rd ram_rd_inst(
        .clk (clk ),
        .rstn (rstn ),
        .sum(sum),
        .ram_rd_data(ram_rd_data),
        .key_state(key_state),
        .pulse(pulse),
        .printtoscreen(printtoscreen),
        .num(num),
        .ram_rd_en (ram_rd_en ),
        .ram_rd_addr (ram_rd_addr)
    );

    reg [23:0] cnt;
    wire [6*8-1:0] seg;
    reg [3:0] led1;
    reg [3:0] key_state2;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            led1 <= 4'b1111;
        end
        else if(key_state != 4'd1)begin
            led1 <= key_state;
        end
    end
    assign led = led1;

    always @(posedge clk or negedge rstn)
    if(!rstn)begin
        cnt <= 0;
    end
    else begin
        cnt <= printtoscreen;
    end

    genvar i;
    generate for(i=0; i<6; i=i+1) begin
            led7seg_decode d(cnt[i*4 +: 4], 1'b1, seg[i*8 +: 8]);
        end
    endgenerate

    seg_driver #(6) driver(clk, rstn, 6'b111111, seg, seg_sel, seg_dig);

endmodule

module seg_driver #(parameter NPorts=8) (
    input clk, rstn,
    input [NPorts-1:0]   valid_i, // input port valid
    input [NPorts*8-1:0] seg_i, // segment inputs
    output reg [NPorts-1:0]  valid_o, // output port valid
    output [7:0]         seg_o // segment outputs
);

    reg [14:0] cnt;
    always @(posedge clk or negedge rstn)
    if(~rstn)
        cnt <= 0;
    else
        cnt <= cnt + 1;

    reg [NPorts-1:0] sel;
    always @(posedge clk or negedge rstn)
    if(~rstn)
        sel <= 0;
    else if(cnt == 0)
        sel <= sel == NPorts - 1 ? 0 : sel + 1;

    always @(sel, valid_i) begin
        valid_o = {NPorts{1'b1}};
        valid_o[sel] = ~valid_i[sel];
    end

    assign seg_o = ~seg_i[sel*8+:8];

endmodule

module led7seg_decode(input [3:0] digit, input valid, output reg [7:0] seg);

    always @(digit)
    if(valid)
        case(digit)
            0: seg = 8'b00111111;
            1: seg = 8'b00000110;
            2: seg = 8'b01011011;
            3: seg = 8'b01001111;
            4: seg = 8'b01100110;
            5: seg = 8'b01101101;
            6: seg = 8'b01111101;
            7: seg = 8'b00000111;
            8: seg = 8'b01111111;
            9: seg = 8'b01101111;
            10: seg = 8'b01110111;
            11: seg = 8'b01111100;
            12: seg = 8'b00111001;
            13: seg = 8'b01011110;
            14: seg = 8'b01111011;
            15: seg = 8'b01110001;
            default: seg = 0;
        endcase
    else seg = 8'd0;

endmodule

module edge_detect(
    input clk, // 时钟信号
    input rstn, // 复位信号
    input [3:0] key_out, // 输入的按键信号
    output [3:0] pulse // 输出的脉冲信号
);
    reg [3:0] key_last; // 上一个时钟周期的按键状态
    reg [3:0] pulse1;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            key_last <= 4'b1111;
            pulse1 <= 4'b0000;
        end else begin
            if (!key_out[0] && key_last[0]) begin
                pulse1 <= 4'b0001;
            end else if (!key_out[1] && key_last[1]) begin
                pulse1 <= 4'b0010;
            end else if (!key_out[2] && key_last[2]) begin
                pulse1 <= 4'b0100;
            end else if (!key_out[3] && key_last[3]) begin
                pulse1 <= 4'b1000; // 产生脉冲信号
            end else begin
                pulse1 <= 4'b0000;
            end
            key_last <= key_out;
        end
    end

    assign pulse = pulse1;

endmodule

module key_debounce(
    input clk, //FPGA clock : 50M
    input rstn,
    input [3:0] key,
    output [3:0] key_out
);

    reg [31:0] delay_cnt; //dealy cnt for 20ms
    reg [3:0] key_reg = 4'b1111;
    reg [3:0] key_value;

    always @(posedge clk) begin
        key_reg <= key;
        if(key_reg != key) //detect the  key state  changed
            delay_cnt <= 32'd1000000; //delay cnt initial time :20ms
        else if(key_reg == key) begin
            if(delay_cnt > 32'd0)
                delay_cnt <= delay_cnt - 32'd1;
            else
                delay_cnt <= delay_cnt;
        end
    end

    always @(posedge clk) begin
        if (~rstn)
            key_value <= 4'b1110;
        else if(delay_cnt == 32'd1) //the key state keep steady for 20ms
            key_value <= key;
        else
            key_value <= 4'b1111;
    end

    assign key_out = key_value;

endmodule

module pulse_timer(
    input clk, // 时钟信号
    input rstn, // 复位信号 (低有效)
    input [3:0] pulse, // 脉冲信号
    output [31:0] timer, // 计时器
    output [3:0] key_state
);

    reg [31:0] timer1;
    reg [3:0] key_state1;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            timer1 <= 32'd0; // 复位时清零
            key_state1 <= 4'b1111;
        end
        else begin
            if (pulse != 4'd0) begin
                key_state1 <= ~pulse;
            end
            if ((key_state1 != 4'd1) && (timer1 != 32'd49_999_999)) begin
                timer1 <= timer1 + 1;
            end
            else if (timer1 == 32'd49_999_999) begin
                timer1 <= 32'd0; // 如果计时器值等于49,999,999，则计时器清零
            end
        end
    end

    assign timer = timer1;
    assign key_state = key_state1;

endmodule

module find(
    input clk,
    input rstn,
    input [19:0] num,
    output [19:0] sum);

    reg [19:0] num_r;
    reg [19:0] sum_r;

    assign sum=sum_r;

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin //由于复位后顺时无法收到num，所以需要自己赋值
            num_r <= 2;
            sum_r <= 4;
        end else begin
            if(num_r != num) begin //当read模块找到新的素数时，num和寄存器num_r中的值不一致时，更新num_r的值
                num_r <= num;
                sum_r <= num+num;
            end else begin
                if(sum_r < 1000000 && sum_r > 1) begin
                    sum_r <= sum_r + num;
                end else if(sum_r >= 1000000) begin
                    sum_r <= 1;
                end
            end
        end
    end
endmodule

module ram_wr(
    input clk,
    input rstn,
    input [19:0] sum,
    output reg ram_wr_we,
    output reg ram_wr_en,
    output [19:0] ram_wr_addr,
    output reg [0:0] ram_wr_data
);
    reg init_state;

    assign ram_wr_addr = {20{rstn}} & sum;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            ram_wr_we <= 1;
            ram_wr_en <= 1;
        end
        else if ((sum < 1000000) && (sum > 1)) begin
            ram_wr_data <= 1;
        end
    end

endmodule

module ram_rd(
    input clk,
    input rstn,
    input [19:0] sum,
    input ram_rd_data,
    input [3:0] key_state,
    input [3:0] pulse,
    output [19:0] printtoscreen, //准备输出到数码管上的素数
    output [19:0] num, //jo需要的素数
    output reg ram_rd_en,
    output reg [19:0] ram_rd_addr
);

    reg [19:0] num1; //jo需要的素数
    reg [19:0] printtoscreen1;
    reg [3:0] delay;
    reg [31:0] count;
    reg [0:0] waitkey;
    reg [0:0] initstate;
    reg [0:0] launch;
    always @(posedge clk or negedge rstn )begin
        if(~rstn)begin
            num1 <= 2;
            ram_rd_addr <= 2;
            printtoscreen1 <= 0;
            delay <= 0;
            count <= 0;
            ram_rd_en <= 1;
            waitkey <= 0;
            initstate <= 1;
            launch <= 1;
        end

        else if ((num1 == 997) && (sum > 999998) && initstate) begin
            waitkey <= 1; //说明已经计算完毕，准备开始向屏幕上输出
            initstate <= 0;
        end

        else if (waitkey && (pulse[0] || launch))begin //接受到按下按键1的脉冲，此时应实现模式1
            ram_rd_addr <= 2; //地址回到2，准备从头输出。
            launch <= 0;
            delay <= 3;
            count <= 0;
        end
        else if (waitkey && pulse[1])begin //接受到按下按键2的脉冲，此时应实现模式2
            ram_rd_addr <= 999984; //地址回到999984，准备从尾输出。
            delay <= 6;
            count <= 0;
        end
        else if (waitkey && pulse[2])begin //接受到按下按键3的脉冲，此时应实现模式3
            ram_rd_addr <= 2; //地址回到2，准备从头输出。
            delay <= 9;
            count <= 0;
        end
        else if (waitkey && pulse[3])begin //接受到按下按键4的脉冲，此时应实现模式4
            ram_rd_addr <= 999984; //地址回到999984，准备从尾输出。
            delay <= 12;
            count <= 0;
        end
        else if ((printtoscreen1 == 999983) && ((key_state[2] == 0) || (key_state[0] == 0))) begin
            printtoscreen1 <= 999983;
        end

        else if((printtoscreen1 == 2) && ((key_state[1] == 0) || (key_state[3] == 0)))begin
            printtoscreen1 <= 2;
        end

        else if (delay == 3) begin //延时三个时钟周期
            if (count < 32'd49_999_997) begin
                count <= count + 1;
            end else begin
                delay <= 4;
            end
        end

        else if (delay == 4) begin
            if (ram_rd_data != 0) begin //检测到地址是合数
                ram_rd_addr <= ram_rd_addr + 1; //继续查找下一个地址
                count <= 32'd49_999_992;
                delay <= 3;
            end
            else if (ram_rd_data == 0) begin //检测到地址是素数
                if (ram_rd_addr != 4) begin
                printtoscreen1 <= ram_rd_addr; //输出当前地址的素数到屏幕上
                count <= 0;
                delay <= 5;
                end else begin
                ram_rd_addr <= ram_rd_addr + 1;
                count <= 32'd49_999_992;
                delay <= 3;
                end
            end
        end

        else if (delay == 5) begin
            ram_rd_addr <= ram_rd_addr + 1;
            delay <= 3;
        end

        else if (delay == 6) begin
            if (count < 32'd49_999_997) begin
                count <= count + 1;
            end else begin
                delay <= 7;
            end
        end

        else if (delay == 7) begin
            if (ram_rd_data != 0) begin //检测到地址是合数
                ram_rd_addr <= ram_rd_addr - 1; //继续逆序查找下一个地址
                count <= 32'd49_999_992;
                delay <= 6;
            end
            else if (ram_rd_data == 0) begin //检测到地址是素数
                printtoscreen1 <= ram_rd_addr; //输出当前地址的素数到屏幕上
                count <= 0;
                delay <= 8;
            end
        end

        else if (delay == 8) begin
            ram_rd_addr <= ram_rd_addr - 1;
            delay <= 6;
        end

        else if (delay == 9) begin //延时三个时钟周期
            if (count < 2) begin
                count <= count + 1;
            end else begin
                delay <= 10;
            end
        end

        else if (delay == 10) begin
            if (ram_rd_data != 0) begin //检测到地址是合数
                ram_rd_addr <= ram_rd_addr + 1; //继续查找下一个地址
                count <= 0;
                delay <= 9;
            end
            else if (ram_rd_data == 0) begin //检测到地址是素数
                printtoscreen1 <= ram_rd_addr; //输出当前地址的素数到屏幕上
                count <= 0;
                delay <= 11;
            end
        end

        else if (delay == 11) begin
            ram_rd_addr <= ram_rd_addr + 1;
            delay <= 9;
        end

        else if(delay == 12) begin
            if (count < 2) begin
                count <= count + 1;
            end else begin
                delay <= 13;
            end
        end

        else if (delay == 13) begin
            if (ram_rd_data != 0) begin //检测到地址是合数
                ram_rd_addr <= ram_rd_addr - 1; //继续逆序查找下一个地址
                count <= 0;
                delay <= 12;
            end
            else if (ram_rd_data == 0) begin //检测到地址是素数
                printtoscreen1 <= ram_rd_addr; //输出当前地址的素数到屏幕上
                count <= 0;
                delay <= 14;
            end
        end

        else if (delay == 14) begin
            ram_rd_addr <= ram_rd_addr - 1;
            delay <= 12;
        end

        else if ((num1 < 997) && (sum > 999998)) begin //该查找下一个地址了
            ram_rd_addr <= ram_rd_addr + 1; //地址加一
            delay <= 2; //进入延时状态
            count <= 0;
        end

        else if (delay == 2) begin //延时三个时钟周期
            if (count < 2) begin
                count <= count + 1;
            end else begin
                delay <= 1;
            end
        end

        else if (delay == 1) begin
            if (ram_rd_data != 0) begin //检测到地址是合数
                ram_rd_addr <= ram_rd_addr + 1; //继续查找下一个地址
                count <= 0;
                delay <= 2;
            end
            else if (ram_rd_data == 0) begin //检测到地址是素数
                num1 <= ram_rd_addr; //输出当前地址的素数
                count <= 0;
                delay <= 0;
            end
        end
        else
            count <= 0;
    end
    assign num = num1;
    assign printtoscreen = printtoscreen1;

endmodule
