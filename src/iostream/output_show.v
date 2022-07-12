`timescale 1ns / 1ps
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Company:
// Engineer:
// 
// Create Date: 2022/05/06 16:56:15
// Design Name:
// Module Name: show
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 


module output_show(input clk,
                   input rst_n,
                   input[39:0] period_show,
                   output[7:0] bit_sel,
                   output[7:0] Y_0, // the first four
                   output[7:0] Y_1);
    reg clkout;
    reg[31:0]cnt;
    reg[2:0]scan_cnt;           // Here is the state count; For examle decide which led light at which time.
    reg[7:0]Y_reg;              // here is used to decide to show whether 1,2,3,or a,b,c
    reg[7:0]bit_sel_reg;        // here is used to choose which one to light;
    reg[4:0]stored_information; // store the information here.
    parameter period = 250000;
    assign Y_0       = Y_reg;
    assign Y_1       = Y_reg;
    assign bit_sel   = bit_sel_reg;
    always@(posedge clk or negedge rst_n) // frequency division;
    begin
        if (!rst_n)
        begin
            cnt <= 0;
            clkout = 0;
        end
        else begin
            if (cnt == (period>>1)-1)
            begin
                clkout = ~clkout;
                cnt <= 0;
            end
            else
                cnt <= cnt+1;
        end
    end
    
    always@(posedge clkout or negedge rst_n) // change scan_cnt based on clkout;
    begin
        if (!rst_n)
            scan_cnt <= 0;
        else begin
            if (scan_cnt == 3'b111)
                scan_cnt <= 0;
            else
                scan_cnt <= scan_cnt+1;
        end
    end
    
    always@(*) // here it chooses which one to light;
    begin
        case(scan_cnt)
            3'b000:bit_sel_reg   = 8'b1000_0000;
            3'b001:bit_sel_reg   = 8'b0100_0000;
            3'b010:bit_sel_reg   = 8'b0010_0000;
            3'b011:bit_sel_reg   = 8'b0001_0000;
            3'b100:bit_sel_reg   = 8'b0000_1000;
            3'b101:bit_sel_reg   = 8'b0000_0100;
            3'b110:bit_sel_reg   = 8'b0000_0010;
            3'b111:bit_sel_reg   = 8'b0000_0001;
            default: bit_sel_reg = 8'b0000_0000;
        endcase
    end
    
    always@(*)
    begin
        case(scan_cnt)
            3'b000:stored_information   = period_show[39:35];
            3'b001:stored_information   = period_show[34:30];
            3'b010:stored_information   = period_show[29:25];
            3'b011:stored_information   = period_show[24:20];
            3'b100:stored_information   = period_show[19:15];
            3'b101:stored_information   = period_show[14:10];
            3'b110:stored_information   = period_show[9:5];
            3'b111:stored_information   = period_show[4:0];
            default: stored_information = 8'b0000_0000;
        endcase
    end
    
    // .         (7)
    // .      ---------
    // .      |       |
    // . (2)  |       | (6)
    // .      |       |
    // .      --------- (1)
    // .      |       |
    // . (3)  |       | (5)
    // .      |       |
    // .      ---------
    // .         (4)
    
    always@(stored_information)
    begin
        case(stored_information)
            0: Y_reg  = 8'b1111_1100; // 0
            1: Y_reg  = 8'b0110_0000; // 1
            2: Y_reg  = 8'b1101_1010; // 2
            3: Y_reg  = 8'b1111_0010; // 3
            4: Y_reg  = 8'b0110_0110; // 4
            5: Y_reg  = 8'b1011_0110; // 5
            6: Y_reg  = 8'b1011_1110; // 6
            7: Y_reg  = 8'b1110_0000; // 7
            8: Y_reg  = 8'b1111_1110; // 8
            9: Y_reg  = 8'b1110_0110; // 9
            10: Y_reg = 8'b1110_1110; // a
            11: Y_reg = 8'b0011_1110; // b
            12: Y_reg = 8'b0001_1010; // c
            13: Y_reg = 8'b0111_1010; // d
            14: Y_reg = 8'b1001_1110; // e
            15: Y_reg = 8'b1000_1110; // f
            16: Y_reg = 8'b0110_1110; // H
            17: Y_reg = 8'b0000_1100; // i
            18: Y_reg = 8'b0111_0000; // j
            19: Y_reg = 8'b0001_1100; // L
            20: Y_reg = 8'b0010_1010; // n
            21: Y_reg = 8'b0011_1010; // o
            22: Y_reg = 8'b1100_1110; // P
            23: Y_reg = 8'b1110_1100; // M
            24: Y_reg = 8'b1000_1100; // r
            25: Y_reg = 8'b0001_1110; // t
            26: Y_reg = 8'b0111_1100; // u
            27: Y_reg = 8'b0010_1000; // v
            28: Y_reg = 8'b0111_0110; // y
            29: Y_reg = 8'b1100_1010; // ?
            30: Y_reg = 8'b1111_0110; // g
            31: Y_reg = 8'b0000_0000; // blank
            
            default:Y_reg = 8'b0000_000; // blank
        endcase
    end
endmodule
    
    // parameter a = 5'd10;
    // parameter b = 5'd11;
    // parameter c = 5'd12;
    // parameter d = 5'd13;
    // parameter e = 5'd14;
    // parameter f = 5'd15;
    // parameter h = 5'd16;
    // parameter i = 5'd17;
    // parameter j = 5'd18;
    // parameter l = 5'd19;
    // parameter n = 5'd20;
    // parameter o = 5'd21;
    // parameter p = 5'd22;
    // parameter q = 5'd23;
    // parameter r = 5'd24;
    // parameter t = 5'd25;
    // parameter u = 5'd26;
    // parameter v = 5'd27;
    // parameter y = 5'd28;
    
    // Y_reg = 8'b0010_1010; // M
