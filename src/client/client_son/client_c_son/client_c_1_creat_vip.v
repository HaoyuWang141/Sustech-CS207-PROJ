module client_c_1_creat_vip (input clk,
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
    // .        G0
    // .       /  \
    // .      G1  G7
    // .      G2
    // .      G3
    // .      G4
    // .      G5
    
    parameter G0 = 3'b000;
    parameter G1 = 3'b001;
    parameter G2 = 3'b010;
    parameter G3 = 3'b011;
    parameter G4 = 3'b100;
    parameter G5 = 3'b101;
    parameter G6 = 3'b110;
    parameter G7 = 3'b111;
    
    reg [2:0] present_state;
    reg [2:0] next_state;
    
    // ----------
    
    reg G2_end;
    reg G3_end;
    reg G4_end;
    reg G5_end;
    reg [19:0] first_password;
    reg [19:0] second_password;
    
    // ----------
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= G0;
        end
        else begin
            if (!en) begin
                present_state <= G0;
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
            next_state    <= G0;
        end
        else begin
            if (!en) begin
                en_father_rst <= 0;
                next_state    <= G0;
            end
            else begin
                case(present_state)
                    G0:
                    begin
                        if (w_vip_i == 2'b01) begin
                            next_state <= G2;
                        end
                        else begin
                            next_state <= G7;
                        end
                    end
                    
                    G2:
                    begin
                        if (G2_end == 1) begin
                            next_state <= G3;
                        end
                        else begin
                            case(press)
                                rls:
                                begin
                                    en_father_rst <= 1;
                                    next_state    <= G0;
                                end
                                ris: next_state <= G0;
                                default:;
                            endcase
                        end
                    end
                    
                    G3:
                    begin
                        if (G3_end == 1) begin
                            next_state <= G4;
                        end
                        else begin
                            case(press)
                                rls: next_state <= G2;
                                ris: next_state <= G0;
                                default:;
                            endcase
                        end
                    end
                    
                    G4:
                    begin
                        if (G4_end == 1) begin
                            if (second_password == first_password) begin
                                next_state <= G5;
                            end
                            else begin
                                next_state <= G6;
                            end
                        end
                        else begin
                            case(press)
                                rls: next_state <= G3;
                                ris: next_state <= G0;
                                default:;
                            endcase
                        end
                    end
                    
                    G5:
                    begin
                        case(press)
                            con:
                            begin
                                en_father_rst <= 1;
                                next_state    <= G0;
                            end
                            rls:
                            begin
                                en_father_rst <= 1;
                                next_state    <= G0;
                            end
                            ris: next_state <= G0;
                            default:;
                        endcase
                    end
                    
                    G6:
                    begin
                        case(press)
                            con: next_state <= G4;
                            rls: next_state <= G4;
                            ris: next_state <= G0;
                            default:;
                        endcase
                    end
                    
                    G7:
                    begin
                        case(press)
                            con:
                            begin
                                en_father_rst <= 1;
                                next_state    <= G0;
                            end
                            rls:
                            begin
                                en_father_rst <= 1;
                                next_state    <= G0;
                            end
                            ris: next_state <= G0;
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
            G2_end               <= 0;
            G3_end               <= 0;
            G4_end               <= 0;
            G5_end               <= 0;
            first_password       <= 'b0;
            second_password      <= 'b0;
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
                G2_end               <= 0;
                G3_end               <= 0;
                G4_end               <= 0;
                G5_end               <= 0;
                first_password       <= 'b0;
                second_password      <= 'b0;
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
                case (present_state)
                    G0:
                    begin
                        G2_end          <= 0;
                        G3_end          <= 0;
                        G4_end          <= 0;
                        G5_end          <= 0;
                        first_password  <= 'b0;
                        second_password <= 'b0;
                        r_en_array_o    <= 0;
                        r_show_o        <= {blank,blank,blank,blank,blank,blank};
                        r_wr_ram_vip_o  <= 2'b00;
                    end
                    G2:
                    begin
                        G3_end       <= 0;
                        G4_end       <= 0;
                        G5_end       <= 0;
                        r_en_array_o <= 0;
                        r_show_o     <= {v,i,p,d,a,y};
                        if (press == con) begin
                            case(switch)
                                8'b0000_0010:
                                begin
                                    r_vip_day_o <= 3'd1;
                                    G2_end      <= 1;
                                end
                                8'b0000_0100:
                                begin
                                    r_vip_day_o <= 3'd2;
                                    G2_end      <= 1;
                                end
                                8'b0000_1000:
                                begin
                                    r_vip_day_o <= 3'd3;
                                    G2_end      <= 1;
                                end
                                8'b0001_0000:
                                begin
                                    r_vip_day_o <= 3'd4;
                                    G2_end      <= 1;
                                end
                                8'b0010_0000:
                                begin
                                    r_vip_day_o <= 3'd5;
                                    G2_end      <= 1;
                                end
                                8'b0100_0000:
                                begin
                                    r_vip_day_o <= 3'd6;
                                    G2_end      <= 1;
                                end
                                8'b1000_0000:
                                begin
                                    r_vip_day_o <= 3'd7;
                                    G2_end      <= 1;
                                end
                                default:;
                            endcase
                        end
                    end
                    
                    G3:
                    begin
                        G2_end   <= 0;
                        G4_end   <= 0;
                        G5_end   <= 0;
                        r_show_o <= {p,blank,20'bz};
                        if (G3_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            
                            if (w_over_array_i == 1) begin
                                first_password <= w_array_input_i;
                                G3_end         <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    G4:
                    begin
                        G2_end   <= 0;
                        G3_end   <= 0;
                        G5_end   <= 0;
                        r_show_o <= {r,p,20'bz};
                        if (G4_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            
                            if (w_over_array_i == 1) begin
                                second_password <= w_array_input_i;
                                G4_end          <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    G5:
                    begin
                        G2_end   <= 0;
                        G3_end   <= 0;
                        G4_end   <= 0;
                        r_show_o <= {5'd6,5'd6,5'd6,5'd6,5'd6,5'd6};
                        if (G5_end == 0) begin
                            r_wr_ram_vip_o       <= 2'b10;
                            r_vip_o              <= 2'b10;
                            r_vip_movie_number_o <= 'b0;
                            r_vip_cost_o         <= 'b0;
                            r_vip_save_o         <= 'b0;
                            r_vip_password_o     <= first_password;
                            r_vip_day_o          <= r_vip_day_o;
                            G5_end               <= 1;
                        end
                        else begin
                            r_wr_ram_vip_o <= 2'b00;
                        end
                    end
                    
                    G6:
                    begin
                        G2_end   <= 0;
                        G3_end   <= 0;
                        G4_end   <= 0;
                        G5_end   <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                    
                    G7:
                    begin
                        G2_end   <= 0;
                        G3_end   <= 0;
                        G4_end   <= 0;
                        G5_end   <= 0;
                        r_show_o <= {c,a,n,t,blank,v};
                    end
                endcase
            end
        end
    end
    
endmodule // client_c_1_creat_vip
