module ram_vip (input clk,
                input rst_n,
                input [1:0] wr_ram_vip,
                input wire [1:0] w_vip_i,
                input wire [4:0] w_vip_movie_number_i,
                input wire [31:0] w_vip_cost_i,
                input wire [31:0] w_vip_save_i,
                input wire [19:0] w_vip_password_i,
                input wire [2:0] w_vip_day_i,
                input wire [4:0] w_vip_off_i,
                output reg [1:0] r_vip_o,
                output reg [4:0] r_vip_movie_number_o,
                output reg [31:0] r_vip_cost_o,
                output reg [31:0] r_vip_save_o,
                output reg [19:0] r_vip_password_o,
                output reg [2:0] r_vip_day_o,
                output reg [4:0] r_vip_off_o,
                input wire can_be_vip,
                output reg [7:0] led);
    
    // wr_ram_vip
    // 00:not write;
    // 01:reset vip(let vip_o be 2'b00);
    // 10:write five reg;
    // 11:write vip off.
    
    // reg vip_o:
    // 00: can't be vip;
    // 01: can be vip but don't have vip;
    // 10: can be vip and have vip but don't activate vip;
    // 11: can be vip and have vip and already activate vip.
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_vip_o              <= 2'b00;
            r_vip_movie_number_o <= 'b0;
            r_vip_cost_o         <= 'b0;
            r_vip_save_o         <= 'b0;
            r_vip_password_o     <= 'b0;
            r_vip_day_o          <= 'b0;
            r_vip_off_o          <= 5'd5;
        end
        else begin
            case (wr_ram_vip)
                2'b00:
                begin
                    if (can_be_vip == 1 && r_vip_o == 2'b00) begin
                        r_vip_o <= 2'b01;
                    end
                end
                2'b01:
                begin
                    r_vip_o              <= 2'b00;
                    r_vip_movie_number_o <= 'b0;
                    r_vip_cost_o         <= 'b0;
                    r_vip_save_o         <= 'b0;
                    r_vip_password_o     <= 'b0;
                    r_vip_day_o          <= 'b0;
                end
                2'b10:
                begin
                    r_vip_o              <= w_vip_i;
                    r_vip_movie_number_o <= w_vip_movie_number_i;
                    r_vip_cost_o         <= w_vip_cost_i;
                    r_vip_save_o         <= w_vip_save_i;
                    r_vip_password_o     <= w_vip_password_i;
                    r_vip_day_o          <= w_vip_day_i;
                end
                2'b11: r_vip_off_o <= w_vip_off_i;
            endcase
        end
    end
    
endmodule // ram_movie
