module manager_b_vip (input clk,
                      input rst_n,
                      input en,
                      output reg en_father_rst,
                      input [2:0] press, // input
                      input [7:0] switch,
                      output reg [29:0] r_show_o,
                      output reg [1:0] r_wr_ram_vip_o, // vip
                      input wire [4:0] w_vip_off_i,
                      output reg [4:0] r_vip_off_o,
                      output reg [7:0] led);
    
    parameter nxt  = 3'b000; // check the next item
    parameter rls  = 3'b001; // return the toppest initial state
    parameter con  = 3'b010; // confirm
    parameter del  = 3'b011; // return last state
    parameter ris  = 3'b100; // delete or check the last item
    parameter none = 3'b111; // do nothing, no button is pressed
    
    parameter idle          = 3'b000; // do nothing - all inout port shoule be high impedance for output
    parameter new           = 3'b001; // add a new item into RAM and return an id (data_io as input, id_io as output)
    parameter read_by_id    = 3'b010; // read and output the data of one item by inputing an id (data_io as output, id_io as input)
    parameter change_by_id  = 3'b011; // change the data of one item by inputing an id (data_io as input, id_io as input)
    parameter delete_by_id  = 3'b100; // delete the data of one item by inputing an id (data_io is not used, id_io as input)
    parameter read_by_index = 3'b101; // (data_io as output, id_io as output)
    parameter clear_all     = 3'b111; // clear all data
    
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
    // .        E0
    // .      /    \
    // .    E1       E3
    // .    E2       E4
    
    parameter E0 = 3'b000;
    parameter E1 = 3'b001;
    parameter E2 = 3'b010;
    parameter E3 = 3'b011;
    parameter E4 = 3'b100;
    
    reg [2:0] present_state;
    reg [2:0] next_state;
    
    // ----------
    
    reg E2_end;
    reg E4_end;
    
    // ----------
    
    // state change
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= E0;
        end
        else begin
            if (!en) begin
                present_state <= E0;
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
            next_state    <= E0;
        end
        else begin
            if (!en) begin
                en_father_rst <= 0;
                next_state    <= E0;
            end
            else begin
                case(present_state)
                    E0:
                    case(press)
                        con:
                        begin
                            case(switch)
                                8'b0000_0001: next_state <= E1;
                                8'b0000_0010: next_state <= E3;
                                default:;
                            endcase
                        end
                        rls: en_father_rst <= 1;
                        default:;
                    endcase
                    
                    E1:
                    case(press)
                        con: next_state <= E2;
                        rls: next_state <= E0;
                        ris: next_state <= E0;
                        default:;
                    endcase
                    
                    E2:
                    if (E2_end == 1) begin
                        next_state <= E0;
                    end
                    else begin
                        case(press)
                            rls: next_state <= E1;
                            ris: next_state <= E0;
                            default:;
                        endcase
                    end
                    
                    E3:
                    case(press)
                        con: next_state <= E4;
                        rls: next_state <= E0;
                        ris: next_state <= E0;
                        default:;
                    endcase
                    
                    E4:
                    if (E4_end == 1) begin
                        next_state <= E0;
                    end
                    else begin
                        case(press)
                            rls: next_state <= E1;
                            ris: next_state <= E0;
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
            E2_end         <= 0;
            E4_end         <= 0;
            r_show_o       <= 'bz;
            r_wr_ram_vip_o <= 'bz;
            r_vip_off_o    <= 'bz;
        end
        else begin
            if (!en) begin
                E2_end         <= 0;
                E4_end         <= 0;
                r_show_o       <= 'bz;
                r_wr_ram_vip_o <= 'bz;
                r_vip_off_o    <= 'bz;
            end
            else begin
                case(present_state)
                    E0:
                    begin
                        E2_end         <= 0;
                        E4_end         <= 0;
                        r_wr_ram_vip_o <= 2'b00;
                        r_show_o       <= {blank,blank,blank,v,i,p};
                    end
                    
                    E1:
                    begin
                        E2_end   <= 0;
                        E4_end   <= 0;
                        r_show_o <= {blank,o,f,f,blank,w_vip_off_i};
                    end
                    
                    E2:
                    begin
                        E4_end   <= 0;
                        r_show_o <= {o,f,f,blank,i,n};
                        if (E2_end == 0) begin
                            if (press == con) begin
                                case(switch)
                                    8'b0000_0001:
                                    begin
                                        r_vip_off_o    <= 5'd1;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b0000_0010:
                                    begin
                                        r_vip_off_o    <= 5'd2;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b0000_0100:
                                    begin
                                        r_vip_off_o    <= 5'd3;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b0000_1000:
                                    begin
                                        r_vip_off_o    <= 5'd4;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b0001_0000:
                                    begin
                                        r_vip_off_o    <= 5'd5;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b0010_0000:
                                    begin
                                        r_vip_off_o    <= 5'd6;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b1000_0000:
                                    begin
                                        r_vip_off_o    <= 5'd7;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b1000_0010:
                                    begin
                                        r_vip_off_o    <= 5'd8;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    8'b1000_0100:
                                    begin
                                        r_vip_off_o    <= 5'd9;
                                        r_wr_ram_vip_o <= 2'b11;
                                        E2_end         <= 1;
                                    end
                                    default:;
                                endcase
                            end
                        end
                        else begin
                            r_wr_ram_vip_o <= 2'b00;
                        end
                    end
                    
                    E3:
                    begin
                        E2_end   <= 0;
                        E4_end   <= 0;
                        r_show_o <= {r,e,v,i,p,5'd29};
                    end
                    
                    E4:
                    begin
                        E2_end   <= 0;
                        r_show_o <= {5'd6,5'd6,5'd6,5'd6,5'd6,5'd6};
                        if (E4_end == 0) begin
                            r_wr_ram_vip_o <= 2'b01;
                            E4_end         <= 1;
                        end
                        else begin
                            r_wr_ram_vip_o <= 2'b00;
                        end
                    end
                endcase
            end
        end
    end
    
    
endmodule
