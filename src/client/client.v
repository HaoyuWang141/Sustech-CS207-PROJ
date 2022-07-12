`include "client/client_son/client_a_buy_ticket.v"
`include "client/client_son/client_b_refund.v"
`include "client/client_son/client_c_vip.v"

module client(input clk,
              input rst_n,
              input en,
              output reg en_father_rst,
              input wire [9:0] w_cinema_time_i,
              input [2:0] press, // input
              input [7:0] switch,
              output wire [3:0] w_target_count_o,
              output wire w_en_array_o,
              input wire w_over_array_i,
              input wire [19:0] w_array_input_i,
              output reg [29:0] r_show_o,                // show
              output wire [2:0] w_ram_movie_operation_o, // movie
              output wire [31:0] w_ram_movie_index_o,
              input wire w_ram_movie_over_i,
              input wire w_ram_movie_wrong_i,
              input wire w_ram_movie_working_i,
              input wire [31:0] w_ram_movie_num_i,
              input wire [5:0] w_ram_movie_id_i,
              output wire [5:0] w_ram_movie_id_o,
              input wire [45:0] w_ram_movie_data_i,
              output wire [45:0] w_ram_movie_data_o,
              output wire [2:0] w_ram_ticket_operation_o, // ticket
              output wire [31:0] w_ram_ticket_index_o,
              input wire w_ram_ticket_over_i,
              input wire w_ram_ticket_wrong_i,
              input wire w_ram_ticket_working_i,
              input wire [31:0] w_ram_ticket_num_i,
              input wire [5:0] w_ram_ticket_id_i,
              output wire [5:0] w_ram_ticket_id_o,
              input wire [64:0] w_ram_ticket_data_i,
              output wire [64:0] w_ram_ticket_data_o,
              output wire [1:0] w_wr_ram_vip_o, // vip
              output wire [1:0] w_vip_o,
              output wire [4:0] w_vip_movie_number_o,
              output wire [31:0] w_vip_cost_o,
              output wire [31:0] w_vip_save_o,
              output wire [19:0] w_vip_password_o,
              output wire [2:0] w_vip_day_o,
              output wire [4:0] w_vip_off_o,
              input wire [1:0] w_vip_i,
              input wire [4:0] w_vip_movie_number_i,
              input wire [31:0] w_vip_cost_i,
              input wire [31:0] w_vip_save_i,
              input wire [19:0] w_vip_password_i,
              input wire [2:0] w_vip_day_i,
              input wire [4:0] w_vip_off_i,
              output wire [4:0] led_small,
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
    
    // ----------
    // client state machine
    // .                             client_state_idle(00)
    // client_state_buy_ticket(01)  client_state_refund(10)  client_state_check_vip(11)
    // ----------
    
    parameter client_state_idle       = 2'b00;
    parameter client_state_buy_ticket = 2'b01;
    parameter client_state_refund     = 2'b10;
    parameter client_state_check_vip  = 2'b11;
    
    reg [1:0] present_state;
    reg [1:0] next_state;
    reg return_initial;
    wire return_initial_a;
    wire return_initial_b;
    wire return_initial_c;
    
    // ---------
    
    reg en_client_state_buy_ticket;
    reg en_client_state_refund;
    reg en_client_state_check_vip;
    
    wire [29:0] w_show_a_o;
    wire [29:0] w_show_c_o;
    wire [29:0] w_show_b_o;
    
    reg [2:0] led_small_second_level;
    assign led_small[2:0] = led_small_second_level;
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= client_state_idle;
        end
        else begin
            if (!en || return_initial) begin
                present_state <= client_state_idle;
            end
            else begin
                present_state <= next_state;
            end
        end
    end
    
    // get next_state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state    <= client_state_idle;
            en_father_rst <= 0;
        end
        else begin
            if (!en || return_initial) begin
                next_state    <= client_state_idle;
                en_father_rst <= 0;
            end
            else begin
                case(present_state)
                    client_state_idle:
                    case(press)
                        con:
                        case (switch)
                            8'b0000_0001: next_state <= client_state_buy_ticket;
                            8'b0000_0010: next_state <= client_state_refund;
                            8'b0000_0100: next_state <= client_state_check_vip;
                        endcase
                        rls: en_father_rst <= 1;
                        default:;
                    endcase
                    
                    default:
                    if (press == ris) begin
                        next_state <= client_state_idle;
                    end
                    else begin
                        ;
                    end
                endcase
            end
        end
    end
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_client_state_buy_ticket <= 0;
            en_client_state_refund     <= 0;
            en_client_state_check_vip  <= 0;
            r_show_o                   <= 'bz;
            return_initial             <= 0;
            led_small_second_level     <= 'bz;
        end
        else begin
            if (!en) begin
                en_client_state_buy_ticket <= 0;
                en_client_state_refund     <= 0;
                en_client_state_check_vip  <= 0;
                r_show_o                   <= 'bz;
                return_initial             <= 0;
                led_small_second_level     <= 'bz;
            end
            else begin
                case (present_state)
                    client_state_idle:
                    begin
                        en_client_state_buy_ticket <= 0;
                        en_client_state_refund     <= 0;
                        en_client_state_check_vip  <= 0;
                        r_show_o                   <= {c,l,i,e,n,t};
                        return_initial             <= 0;
                        led_small_second_level     <= 3'b000;
                    end
                    client_state_buy_ticket:
                    begin
                        en_client_state_buy_ticket <= 1;
                        en_client_state_refund     <= 0;
                        en_client_state_check_vip  <= 0;
                        r_show_o                   <= w_show_a_o;
                        return_initial             <= return_initial_a;
                        led_small_second_level     <= 3'b001;
                    end
                    client_state_refund:
                    begin
                        en_client_state_buy_ticket <= 0;
                        en_client_state_refund     <= 1;
                        en_client_state_check_vip  <= 0;
                        r_show_o                   <= w_show_b_o;
                        return_initial             <= return_initial_b;
                        led_small_second_level     <= 3'b010;
                    end
                    client_state_check_vip:
                    begin
                        en_client_state_buy_ticket <= 0;
                        en_client_state_refund     <= 0;
                        en_client_state_check_vip  <= 1;
                        r_show_o                   <= w_show_c_o;
                        return_initial             <= return_initial_c;
                        led_small_second_level     <= 3'b100;
                    end
                endcase
            end
        end
    end
    
    // ----------
    
    client_a_buy_ticket u_client_a_buy_ticket
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_client_state_buy_ticket),
    .en_father_rst(return_initial_a),
    .w_cinema_time_i(w_cinema_time_i),
    
    .press(press),
    .switch(switch),
    .r_target_count_o(w_target_count_o),
    .r_en_array_o(w_en_array_o),
    .w_over_array_i(w_over_array_i),
    .w_array_input_i(w_array_input_i),
    .r_show_o(w_show_a_o),
    
    .r_ram_movie_operation_o(w_ram_movie_operation_o),
    .r_ram_movie_index_o(w_ram_movie_index_o),
    .w_ram_movie_over_i(w_ram_movie_over_i),
    .w_ram_movie_num_i(w_ram_movie_num_i),
    .r_ram_movie_id_o(w_ram_movie_id_o),
    .w_ram_movie_data_i(w_ram_movie_data_i),
    .r_ram_movie_data_o(w_ram_movie_data_o),
    
    .r_ram_ticket_operation_o(w_ram_ticket_operation_o),
    .r_ram_ticket_index_o(w_ram_ticket_index_o),
    .w_ram_ticket_over_i(w_ram_ticket_over_i),
    .w_ram_ticket_id_i(w_ram_ticket_id_i),
    .r_ram_ticket_data_o(w_ram_ticket_data_o),
    
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
    
    client_b_refund u_client_b_refund
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_client_state_refund),
    .en_father_rst(return_initial_b),
    
    .press(press),
    .switch(switch),
    .r_target_count_o(w_target_count_o),
    .r_en_array_o(w_en_array_o),
    .w_over_array_i(w_over_array_i),
    .w_array_input_i(w_array_input_i),
    .r_show_o(w_show_b_o),
    
    .r_ram_movie_operation_o(w_ram_movie_operation_o),
    .r_ram_movie_index_o(w_ram_movie_index_o),
    .w_ram_movie_over_i(w_ram_movie_over_i),
    .r_ram_movie_id_o(w_ram_movie_id_o),
    .w_ram_movie_data_i(w_ram_movie_data_i),
    .r_ram_movie_data_o(w_ram_movie_data_o),
    
    .r_ram_ticket_operation_o(w_ram_ticket_operation_o),
    .r_ram_ticket_index_o(w_ram_ticket_index_o),
    .w_ram_ticket_over_i(w_ram_ticket_over_i),
    .w_ram_ticket_wrong_i(w_ram_ticket_wrong_i),
    .w_ram_ticket_num_i(w_ram_ticket_num_i),
    .r_ram_ticket_id_o(w_ram_ticket_id_o),
    .w_ram_ticket_data_i(w_ram_ticket_data_i),
    .r_ram_ticket_data_o(w_ram_ticket_data_o),
    
    .r_wr_ram_vip_o(w_wr_ram_vip_o),
    .r_vip_o(w_vip_o),
    .r_vip_movie_number_o(w_vip_movie_number_o),
    .r_vip_cost_o(w_vip_cost_o),
    .r_vip_save_o(w_vip_save_o),
    .r_vip_password_o(w_vip_password_o),
    .r_vip_day_o(w_vip_day_o),
    .r_vip_off_o(w_vip_off_o),
    
    .w_vip_i(w_vip_i),
    .w_vip_movie_number_i(w_vip_movie_number_i),
    .w_vip_cost_i(w_vip_cost_i),
    .w_vip_save_i(w_vip_save_i),
    .w_vip_password_i(w_vip_password_i),
    .w_vip_day_i(w_vip_day_i),
    .w_vip_off_i(w_vip_off_i)
    );
    
    client_c_vip u_client_c_vip
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_client_state_check_vip),
    .en_father_rst(return_initial_c),
    
    .press(press),
    .switch(switch),
    .w_target_count_o(w_target_count_o),
    .w_en_array_o(w_en_array_o),
    .w_over_array_i(w_over_array_i),
    .w_array_input_i(w_array_input_i),
    .r_show_o(w_show_c_o),
    
    .w_wr_ram_vip_o(w_wr_ram_vip_o),
    .w_vip_o(w_vip_o),
    .w_vip_movie_number_o(w_vip_movie_number_o),
    .w_vip_cost_o(w_vip_cost_o),
    .w_vip_save_o(w_vip_save_o),
    .w_vip_password_o(w_vip_password_o),
    .w_vip_day_o(w_vip_day_o),
    
    .w_vip_i(w_vip_i),
    .w_vip_movie_number_i(w_vip_movie_number_i),
    .w_vip_cost_i(w_vip_cost_i),
    .w_vip_save_i(w_vip_save_i),
    .w_vip_password_i(w_vip_password_i),
    .w_vip_day_i(w_vip_day_i),
    .w_vip_off_i(w_vip_off_i),
    
    .led_small(led_small[4:3])
    );
    
    
endmodule
