module client_c_2_activate_vip (input clk,
                                input rst_n,
                                input en,
                                output reg en_father_rst,
                                input [2:0] press, // input
                                input [7:0] switch,
                                output reg [3:0] r_target_count_o,
                                output reg r_en_array_o,
                                input wire w_over_array_i,
                                input wire [19:0] w_array_input_i,
                                output reg [29:0] r_show_o,      // show
                                output reg [1:0] r_wr_ram_vip_o, // vip
                                output reg [1:0] r_vip_o,
                                output reg [4:0] r_vip_movie_number_o,
                                output reg [31:0] r_vip_cost_o,
                                output reg [31:0] r_vip_save_o,
                                output reg [19:0] r_vip_password_o,
                                output reg [2:0] r_vip_day_o,
                                input wire [1:0] w_vip_i,
                                input wire [4:0] w_vip_movie_number_i,
                                input wire [31:0] w_vip_cost_i,
                                input wire [31:0] w_vip_save_i,
                                input wire [19:0] w_vip_password_i,
                                input wire [2:0] w_vip_day_i,
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
    // .        H0
    // .       /  \
    // .      H1  H4
    // .     /  \
    // .    H2  H3
    
    parameter H0 = 3'b000;
    parameter H1 = 3'b001;
    parameter H2 = 3'b010;
    parameter H3 = 3'b011;
    parameter H4 = 3'b100;
    
    reg [2:0] present_state;
    reg [2:0] next_state;
    
    reg count_begin;
    reg H1_end;
    reg H2_end;
    
    // time div
    integer cnt;
    parameter PERIOD = 100_000_000;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end
        else begin
            if (!en) begin
                cnt <= 0;
            end
            else begin
                if (cnt == PERIOD - 1) begin
                    cnt <= 0;
                end
                else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end
    
    // count down 10s
    reg [4:0] time_remain;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_remain <= 5'd9;
        end
        else begin
            if (!en) begin
                time_remain <= 5'd9;
            end
            else begin
                if (count_begin == 1) begin
                    if (cnt == PERIOD - 1 && time_remain > 0) begin
                        time_remain <= time_remain - 1;
                    end
                end
                else begin
                    time_remain <= 5'd9;
                end
            end
        end
    end
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= H0;
        end
        else begin
            if (!en) begin
                present_state <= H0;
            end
            else begin
                present_state <= next_state;
            end
        end
    end
    
    // get next state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_father_rst <= 0;
            next_state    <= H0;
        end
        else begin
            if (!en) begin
                en_father_rst <= 0;
                next_state    <= H0;
            end
            else begin
                case(present_state)
                    H0:
                    begin
                        if (w_vip_i == 2'b10) begin
                            next_state <= H1;
                        end
                        else begin
                            next_state <= H4;
                        end
                    end
                    
                    H1:
                    begin
                        if (H1_end == 1) begin
                            if (time_remain == 1) begin
                                next_state <= H4;
                            end
                            else begin
                                if (w_array_input_i == w_vip_password_i) begin
                                    next_state <= H2;
                                end
                                else begin
                                    next_state <= H4;
                                end
                            end
                        end
                        else begin
                            case(press)
                                rls:
                                begin
                                    en_father_rst <= 1;
                                    next_state    <= H0;
                                end
                                ris: next_state <= H0;
                                default:;
                            endcase
                        end
                    end
                    
                    H2:
                    begin
                        if (H2_end == 1) begin
                            case(press)
                                con:
                                begin
                                    en_father_rst <= 1;
                                    next_state    <= H0;
                                end
                                rls:
                                begin
                                    en_father_rst <= 1;
                                    next_state    <= H0;
                                end
                                ris: next_state <= H0;
                                default:;
                            endcase
                        end
                        else begin
                            if (press == ris) begin
                                next_state <= H0;
                            end
                        end
                    end
                    
                    H4:
                    begin
                        case(press)
                            con:
                            begin
                                en_father_rst <= 1;
                                next_state    <= H0;
                            end
                            rls:
                            begin
                                en_father_rst <= 1;
                                next_state    <= H0;
                            end
                            ris: next_state <= H0;
                            default:;
                        endcase
                    end
                endcase
            end
        end
    end
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_begin          <= 0;
            H1_end               <= 0;
            H2_end               <= 0;
            r_target_count_o     <= 'bz;
            r_en_array_o         <= 'bz;
            r_show_o             <= 'bz;
            r_wr_ram_vip_o       <= 'bz;
            r_vip_o              <= 'bz;
            r_vip_movie_number_o <= 'bz;
            r_vip_cost_o         <= 'bz;
            r_vip_save_o         <= 'bz;
            r_vip_password_o     <= 'bz;
            r_vip_day_o          <= 'bz;
        end
        else begin
            if (!en) begin
                count_begin          <= 0;
                H1_end               <= 0;
                H2_end               <= 0;
                r_en_array_o         <= 'bz;
                r_target_count_o     <= 'bz;
                r_show_o             <= 'bz;
                r_wr_ram_vip_o       <= 'bz;
                r_vip_o              <= 'bz;
                r_vip_movie_number_o <= 'bz;
                r_vip_cost_o         <= 'bz;
                r_vip_save_o         <= 'bz;
                r_vip_password_o     <= 'bz;
                r_vip_day_o          <= 'bz;
            end
            else begin
                case(present_state)
                    H0:
                    begin
                        H1_end         <= 0;
                        H2_end         <= 0;
                        r_en_array_o   <= 0;
                        r_show_o       <= {blank,blank,blank,blank,blank,blank};
                        r_wr_ram_vip_o <= 2'b00;
                    end
                    
                    H1:
                    begin
                        H2_end <= 0;
                        if (H1_end == 0) begin
                            r_show_o         <= {time_remain,blank,20'bz};
                            count_begin      <= 1;
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            if (w_over_array_i == 1 || time_remain == 0) begin
                                H1_end <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                            count_begin  <= 0;
                        end
                    end
                    
                    H2:
                    begin
                        H1_end   <= 0;
                        r_show_o <= {5'd6,5'd6,5'd6,5'd6,5'd6,5'd6};
                        if (H2_end == 0) begin
                            r_wr_ram_vip_o       <= 2'b10;
                            r_vip_o              <= 2'b11;
                            r_vip_movie_number_o <= w_vip_movie_number_i;
                            r_vip_cost_o         <= w_vip_cost_i;
                            r_vip_save_o         <= w_vip_save_i;
                            r_vip_password_o     <= w_vip_password_i;
                            r_vip_day_o          <= w_vip_day_i;
                            H2_end               <= 1;
                        end
                        else begin
                            r_wr_ram_vip_o <= 2'b00;
                        end
                    end
                    
                    H4:
                    begin
                        H1_end   <= 0;
                        H2_end   <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                endcase
            end
        end
    end
    
endmodule // client_c_2_activate_vip
