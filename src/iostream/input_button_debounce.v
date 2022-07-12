// reference: https:// blog.csdn.net/ssj925319/article/details/118708113
module input_button_debounce(input clk,
                       input rst_n,
                       input [4:0] button,
                       output reg [2:0] press);
    
    // buttons on FPGA:
    // . x .            top               4
    // x x x    left    mid    right    3 2 0
    // . x .            down              1
    // when the button is pressed, it is truned into high level. Otherwise, it is in low level.
    // input is five buttons, and output is one 3-bit binary number, which means this module is a encoder.
    
    parameter	DELAY_TIME    = 2000_000;
    // parameter DELAY_TIME = 5;
    reg key;
    reg	key_r0;		     // 同步 当前时钟周期输入状态
    reg	key_r1;		     // 打拍 前一个时钟周期输入的状态
    wire key_pedge;		 // 上升沿
    
    integer delay_cnt; // 计数20ms，需要20ms/10ns = 1000_000个时钟周期
    reg	delay_flag;    // 按下的上升沿标志
    
    initial begin
        key        = 0;
        key_r0     = 0;
        key_r1     = 0;
        delay_flag = 0;
        delay_cnt  = 0;press  = 0;
    end
    
    // 同步计数实现
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            key_r0 <= 1'b0;
            key_r1 <= 1'b0;
        end
        else begin
            if (button>0) begin
                key <= 1;
            end
            else begin
                key <= 0;
            end
            key_r0 <= key;
            key_r1 <= key_r0;
        end
    end
    
    assign key_pedge = ~key_r1 & key_r0 ; // 检测上升沿
    
    // delay_flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_flag <= 1'b0;
        end
        else begin
            if (key_pedge) begin
                delay_flag <= 1'b1;
            end
            else begin
                if (delay_cnt == DELAY_TIME - 1) begin
                    delay_flag <= 1'b0;
                end
            end
        end
    end
    
    // delay_cnt 计数器计满2000_000个时钟周期
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_cnt <= 0;
        end
        else begin
            if (delay_flag) begin
                if (delay_cnt == DELAY_TIME - 1) begin
                    delay_cnt <= 0;
                end
                else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
        end
    end
    
    // press
    
    // buttons on FPGA:
    // . x .            top               4
    // x x x    left    mid    right    3 2 0
    // . x .            down              1
    // 0: button_next
    // 1: button_return_last_state
    // 2: button_confirm
    // 3: button_delete_or_last
    // 4: button_return_initial_state
    
    // ..button..
    // 4 3 2 1 0 output digit
    // 0 0 0 0 1  000    0
    // 0 0 0 1 x  001    1
    // 0 0 1 x x  010    2
    // 0 1 x x x  011    3
    // 1 x x x x  100    4
    // 0 0 0 0 0  111    7
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            press <= 3'b111;
        end
        else begin
            if (delay_cnt == DELAY_TIME - 1) begin
                case (button)
                    5'b00_001 : press <= 3'b000;
                    5'b00_010 : press <= 3'b001;
                    5'b00_100 : press <= 3'b010;
                    5'b01_000 : press <= 3'b011;
                    5'b10_000 : press <= 3'b100;
                    5'b00_000 : press <= 3'b111;
                endcase
            end
            else begin
                press <= 3'b111;
            end
        end
    end
    
endmodule
    
