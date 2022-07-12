`include "client/client_son/client_c_son/client_c_1_creat_vip.v"
`include "client/client_son/client_c_son/client_c_2_activate_vip.v"
`include "client/client_son/client_c_son/client_c_3_check_vip.v"

module client_c_vip (input clk,
                     input rst_n,
                     input en,
                     output reg en_father_rst,
                     input [2:0] press, // input
                     input [7:0] switch,
                     output wire [3:0] w_target_count_o,
                     output wire w_en_array_o,
                     input wire w_over_array_i,
                     input wire [19:0] w_array_input_i,
                     output reg [29:0] r_show_o,       // show
                     output wire [1:0] w_wr_ram_vip_o, // vip
                     output wire [1:0] w_vip_o,
                     output wire [4:0] w_vip_movie_number_o,
                     output wire [31:0] w_vip_cost_o,
                     output wire [31:0] w_vip_save_o,
                     output wire [19:0] w_vip_password_o,
                     output wire [2:0] w_vip_day_o,
                     input wire [1:0] w_vip_i,
                     input wire [4:0] w_vip_movie_number_i,
                     input wire [31:0] w_vip_cost_i,
                     input wire [31:0] w_vip_save_i,
                     input wire [19:0] w_vip_password_i,
                     input wire [2:0] w_vip_day_i,
                     input wire [4:0] w_vip_off_i,
                     output wire [1:0] led_small,
                     output reg [7:0] led);
    
    parameter nxt  = 3'b000; // check the next item
    parameter rls  = 3'b001; // return the toppest initial state
    parameter con  = 3'b010; // confirm
    parameter del  = 3'b011; // return last state
    parameter ris  = 3'b100; // delete or check the last item
    parameter none = 3'b111; // do nothing, no button is pressed
    
    // parameter for output (show_i)
    parameter a     = 5'd10;
    parameter b     = 5'd11;
    parameter c     = 5'd12;
    parameter d     = 5'd13;
    parameter e     = 5'd14;
    parameter f     = 5'd15;
    parameter h     = 5'd16;
    parameter i     = 5'd17;
    parameter j     = 5'd18;
    parameter l     = 5'd19;
    parameter n     = 5'd20;
    parameter o     = 5'd21;
    parameter p     = 5'd22;
    parameter m     = 5'd23;
    parameter r     = 5'd24;
    parameter t     = 5'd25;
    parameter u     = 5'd26;
    parameter v     = 5'd27;
    parameter y     = 5'd28;
    parameter g     = 5'd30;
    parameter blank = 5'd31;
    
    // state:
    // .         C0
    // .       / | \
    // .      C1 C2 C3
    
    parameter C0 = 2'b00;
    parameter C1 = 2'b01;
    parameter C2 = 2'b10;
    parameter C3 = 2'b11;
    
    reg [1:0] present_state;
    reg [1:0] next_state;
    reg return_initial;
    wire return_initial_c1;
    wire return_initial_c2;
    wire return_initial_c3;
    
    // ----------
    
    reg en_C1;
    reg en_C2;
    reg en_C3;
    
    wire [29:0] w_show_c1_o;
    wire [29:0] w_show_c2_o;
    wire [29:0] w_show_c3_o;
    
    reg [1:0] led_small_third_level;
    assign led_small = led_small_third_level;
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= C0;
        end
        else begin
            if (!en || return_initial) begin
                present_state <= C0;
            end
            else begin
                present_state <= next_state;
            end
        end
    end
    
    // get next state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state    <= C0;
            en_father_rst <= 0;
        end
        else begin
            if (!en || return_initial) begin
                next_state    <= C0;
                en_father_rst <= 0;
            end
            else begin
                case(present_state)
                    C0:
                    case(press)
                        con:
                        begin
                            case(switch)
                                8'b0000_0001: next_state <= C1;
                                8'b0000_0010: next_state <= C2;
                                8'b0000_0100: next_state <= C3;
                                default:;
                            endcase
                        end
                        rls: en_father_rst <= 1;
                        default:;
                    endcase
                    
                    default:
                    begin
                        if (press == ris) begin
                            next_state <= C0;
                        end
                        else begin
                            ;
                        end
                    end
                endcase
            end
        end
    end
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_C1                 <= 0;
            en_C2                 <= 0;
            en_C3                 <= 0;
            r_show_o              <= 'bz;
            return_initial        <= 0;
            led_small_third_level <= 'bz;
        end
        else begin
            if (!en) begin
                en_C1                 <= 0;
                en_C2                 <= 0;
                en_C3                 <= 0;
                r_show_o              <= 'bz;
                return_initial        <= 0;
                led_small_third_level <= 'bz;
            end
            else begin
                case (next_state)
                    C0:
                    begin
                        en_C1                 <= 0;
                        en_C2                 <= 0;
                        en_C3                 <= 0;
                        r_show_o              <= {blank,blank,blank,v,i,p};
                        return_initial        <= 0;
                        led_small_third_level <= 2'b00;
                    end
                    C1:
                    begin
                        en_C1                 <= 1;
                        en_C2                 <= 0;
                        en_C3                 <= 0;
                        r_show_o              <= w_show_c1_o;
                        return_initial        <= return_initial_c1;
                        led_small_third_level <= 2'b01;
                    end
                    C2:
                    begin
                        en_C1                 <= 0;
                        en_C2                 <= 1;
                        en_C3                 <= 0;
                        r_show_o              <= w_show_c2_o;
                        return_initial        <= return_initial_c2;
                        led_small_third_level <= 2'b10;
                    end
                    C3:
                    begin
                        en_C1                 <= 0;
                        en_C2                 <= 0;
                        en_C3                 <= 1;
                        r_show_o              <= w_show_c3_o;
                        return_initial        <= return_initial_c3;
                        led_small_third_level <= 2'b11;
                    end
                endcase
            end
        end
    end
    
    // ----------
    
    client_c_1_creat_vip u_client_c_1_creat_vip
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_C1),
    .en_father_rst(return_initial_c1),
    
    .press(press),
    .switch(switch),
    .r_target_count_o(w_target_count_o),
    .r_en_array_o(w_en_array_o),
    .w_over_array_i(w_over_array_i),
    .w_array_input_i(w_array_input_i),
    .r_show_o(w_show_c1_o),
    
    .r_wr_ram_vip_o(w_wr_ram_vip_o),
    .r_vip_o(w_vip_o),
    .r_vip_movie_number_o(w_vip_movie_number_o),
    .r_vip_cost_o(w_vip_cost_o),
    .r_vip_save_o(w_vip_save_o),
    .r_vip_password_o(w_vip_password_o),
    .r_vip_day_o(w_vip_day_o),
    .w_vip_i(w_vip_i)
    );
    
    client_c_2_activate_vip u_client_c_2_activate_vip
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_C2),
    .en_father_rst(return_initial_c2),
    
    .press(press),
    .switch(switch),
    .r_target_count_o(w_target_count_o),
    .r_en_array_o(w_en_array_o),
    .w_over_array_i(w_over_array_i),
    .w_array_input_i(w_array_input_i),
    .r_show_o(w_show_c2_o),
    
    .r_wr_ram_vip_o(w_wr_ram_vip_o),
    .r_vip_o(w_vip_o),
    .r_vip_movie_number_o(w_vip_movie_number_o),
    .r_vip_cost_o(w_vip_cost_o),
    .r_vip_save_o(w_vip_save_o),
    .r_vip_password_o(w_vip_password_o),
    .r_vip_day_o(w_vip_day_o),
    
    .w_vip_i(w_vip_i),
    .w_vip_movie_number_i(w_vip_movie_number_i),
    .w_vip_cost_i(w_vip_cost_i),
    .w_vip_save_i(w_vip_save_i),
    .w_vip_password_i(w_vip_password_i),
    .w_vip_day_i(w_vip_day_i)
    );
    
    client_c_3_check_vip u_client_c_3_check_vip
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_C3),
    .en_father_rst(return_initial_c3),
    
    .press(press),
    .switch(switch),
    .r_target_count_o(w_target_count_o),
    .r_en_array_o(w_en_array_o),
    .w_over_array_i(w_over_array_i),
    .w_array_input_i(w_array_input_i),
    .r_show_o(w_show_c3_o),
    
    .r_wr_ram_vip_o(w_wr_ram_vip_o),
    .r_vip_o(w_vip_o),
    .r_vip_movie_number_o(w_vip_movie_number_o),
    .r_vip_cost_o(w_vip_cost_o),
    .r_vip_save_o(w_vip_save_o),
    .r_vip_password_o(w_vip_password_o),
    .r_vip_day_o(w_vip_day_o),
    
    .w_vip_i(w_vip_i),
    .w_vip_movie_number_i(w_vip_movie_number_i),
    .w_vip_cost_i(w_vip_cost_i),
    .w_vip_save_i(w_vip_save_i),
    .w_vip_password_i(w_vip_password_i),
    .w_vip_day_i(w_vip_day_i),
    .w_vip_off_i(w_vip_off_i)
    );
    
endmodule // client_refund
