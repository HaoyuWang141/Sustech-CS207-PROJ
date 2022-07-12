`include "binary_to_08421.v"

module client_c_3_check_vip (input clk,
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
                             input wire [4:0] w_vip_off_i,
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
    // .         I0 -> I10
    // .         I1
    // .         I2
    // .         I2
    // .        /  \
    // .      / |  | \
    // .     I3 I4 I5 I6
    // .              I7 -> I9
    // .              I8
    
    parameter I0  = 4'b0000;
    parameter I1  = 4'b0001;
    parameter I2  = 4'b0010;
    parameter I3  = 4'b0011;
    parameter I4  = 4'b0100;
    parameter I5  = 4'b0101;
    parameter I6  = 4'b0110;
    parameter I7  = 4'b0111;
    parameter I8  = 4'b1000;
    parameter I9  = 4'b1001;
    parameter I10 = 4'b1010;
    parameter I11 = 4'b1011;
    parameter I12 = 4'b1100;
    parameter I13 = 4'b1101;
    
    reg [3:0] present_state;
    reg [3:0] next_state;
    
    reg I1_end;
    reg I12_end;
    reg I6_end;
    reg I7_end;
    reg I8_end;
    reg [19:0] first_password;
    reg [19:0] second_password;
    
    wire [19:0] w_vip_cost;
    wire [19:0] w_vip_save;
    
    // ----------
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= I0;
        end
        else begin
            if (!en) begin
                present_state <= I0;
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
            next_state    <= I0;
        end
        else begin
            if (!en) begin
                en_father_rst <= 0;
                next_state    <= I0;
            end
            else begin
                case(present_state)
                    I0:
                    begin
                        if (w_vip_i == 2'b11) begin
                            next_state <= I1;
                        end
                        else begin
                            next_state <= I10;
                        end
                    end
                    
                    I1:
                    begin
                        if (I1_end == 1) begin
                            if (w_array_input_i == w_vip_password_i) begin
                                next_state <= I2;
                            end
                            else begin
                                next_state <= I11;
                            end
                        end
                        else begin
                            case(press)
                                rls:
                                begin
                                    en_father_rst <= 1;
                                    next_state    <= I0;
                                end
                                ris: next_state <= I0;
                                default:;
                            endcase
                        end
                    end
                    
                    I2:
                    begin
                        case(press)
                            con:
                            begin
                                case(switch)
                                    8'b0000_0001: next_state <= I3;
                                    8'b0000_0010: next_state <= I4;
                                    8'b0000_0100: next_state <= I5;
                                    8'b0000_1000: next_state <= I6;
                                    8'b0001_0000: next_state <= I13;
                                endcase
                            end
                            rls:
                            begin
                                en_father_rst <= 1;
                                next_state    <= I0;
                            end
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I3:
                    begin
                        case(press)
                            con: next_state <= I12;
                            rls: next_state <= I2;
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I4:
                    begin
                        case(press)
                            con: next_state <= I2;
                            rls: next_state <= I2;
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I5:
                    begin
                        case(press)
                            con: next_state <= I2;
                            rls: next_state <= I2;
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I6:
                    begin
                        if (I6_end == 1) begin
                            next_state <= I7;
                        end
                        else begin
                            case(press)
                                rls: next_state <= I2;
                                ris: next_state <= I0;
                                default:;
                            endcase
                        end
                    end
                    
                    I7:
                    begin
                        if (I7_end == 1) begin
                            if (second_password == first_password) begin
                                next_state <= I8;
                            end
                            else begin
                                next_state <= I9;
                            end
                        end
                        else begin
                            case(press)
                                rls: next_state <= I6;
                                ris: next_state <= I0;
                                default:;
                            endcase
                        end
                    end
                    
                    I8:
                    begin
                        case(press)
                            con: next_state <= I2;
                            rls: next_state <= I2;
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I9:
                    begin
                        case(press)
                            con: next_state <= I7;
                            rls: next_state <= I7;
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I10:
                    begin
                        case(press)
                            con:
                            begin
                                en_father_rst <= 1;
                                next_state    <= I0;
                            end
                            rls:
                            begin
                                en_father_rst <= 1;
                                next_state    <= I0;
                            end
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I11:
                    begin
                        case(press)
                            con: next_state <= I1;
                            rls: next_state <= I1;
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I12:
                    begin
                        case(press)
                            con:
                            begin
                                en_father_rst <= 1;
                                next_state    <= I0;
                            end
                            rls:
                            begin
                                en_father_rst <= 1;
                                next_state    <= I0;
                            end
                            ris: next_state <= I0;
                            default:;
                        endcase
                    end
                    
                    I13:
                    begin
                        case(press)
                            con: next_state <= I2;
                            rls: next_state <= I2;
                            ris: next_state <= I0;
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
            I1_end               <= 0;
            I6_end               <= 0;
            I7_end               <= 0;
            I8_end               <= 0;
            I12_end              <= 0;
            first_password       <= 20'b0;
            second_password      <= 20'b0;
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
            if (!en) begin
                I1_end               <= 0;
                I6_end               <= 0;
                I7_end               <= 0;
                I8_end               <= 0;
                I12_end              <= 0;
                first_password       <= 20'b0;
                second_password      <= 20'b0;
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
                    I0:
                    begin
                        I1_end          <= 0;
                        I6_end          <= 0;
                        I7_end          <= 0;
                        I8_end          <= 0;
                        I12_end         <= 0;
                        first_password  <= 20'b0;
                        second_password <= 20'b0;
                        r_en_array_o    <= 0;
                        r_show_o        <= {blank,blank,blank,blank,blank,blank};
                        r_wr_ram_vip_o  <= 2'b00;
                    end
                    
                    I1:
                    begin
                        r_show_o <= {p,blank,20'bz};
                        if (I1_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            if (w_over_array_i == 1) begin
                                I1_end <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    I2:
                    begin
                        I1_end       <= 0;
                        I6_end       <= 0;
                        I7_end       <= 0;
                        I8_end       <= 0;
                        I12_end      <= 0;
                        r_en_array_o <= 0;
                        r_show_o     <= {u,blank,d,o,blank,5'd29};
                    end
                    
                    I3:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {c,a,n,c,e,l};
                    end
                    
                    I4:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {c,o,w_vip_cost};
                    end
                    
                    I5:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {5'd5,a,w_vip_save};
                    end
                    
                    I6:
                    begin
                        I1_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {p,blank,20'bz};
                        if (I6_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            if (w_over_array_i == 1) begin
                                first_password <= w_array_input_i;
                                I6_end         <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    I7:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {r,p,20'bz};
                        if (I7_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            if (w_over_array_i == 1) begin
                                second_password <= w_array_input_i;
                                I7_end          <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    I8:
                    begin
                        I1_end  <= 0;
                        I6_end  <= 0;
                        I7_end  <= 0;
                        I12_end <= 0;
                        if (I8_end == 0) begin
                            r_show_o             <= {5'd6,5'd6,5'd6,5'd6,5'd6,5'd6};
                            r_wr_ram_vip_o       <= 2'b10;
                            r_vip_o              <= w_vip_i;
                            r_vip_movie_number_o <= w_vip_movie_number_i;
                            r_vip_cost_o         <= w_vip_cost_i;
                            r_vip_save_o         <= w_vip_save_i;
                            r_vip_password_o     <= first_password;
                            r_vip_day_o          <= w_vip_day_i;
                            I8_end               <= 1;
                        end
                        else begin
                            r_wr_ram_vip_o <= 2'b00;
                        end
                    end
                    
                    I9:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                    
                    I10:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {n,o,blank,v,i,p};
                    end
                    
                    I11:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                    
                    I12:
                    begin
                        I1_end <= 0;
                        I6_end <= 0;
                        I7_end <= 0;
                        I8_end <= 0;
                        if (I12_end == 0) begin
                            r_show_o       <= {5'd6,5'd6,5'd6,5'd6,5'd6,5'd6};
                            r_wr_ram_vip_o <= 2'b01;
                            I12_end        <= 1;
                        end
                        else begin
                            r_wr_ram_vip_o <= 2'b00;
                        end
                    end
                    
                    I13:
                    begin
                        I1_end   <= 0;
                        I6_end   <= 0;
                        I7_end   <= 0;
                        I8_end   <= 0;
                        I12_end  <= 0;
                        r_show_o <= {blank,o,f,f,blank,w_vip_off_i};
                    end
                endcase
            end
        end
    end
    
    binary_to_08421 u_binary_to_08421_cc3_1
    (
    .in(w_vip_cost_i),
    .out(w_vip_cost)
    );
    
    binary_to_08421 u_binary_to_08421_cc3_2
    (
    .in(w_vip_save_i),
    .out(w_vip_save)
    );
    
    
endmodule // client_c_3_check_vip
