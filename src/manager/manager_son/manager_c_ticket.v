`include "binary_to_08421.v"

module manager_c_ticket (input clk,
                         input rst_n,
                         input en,
                         output reg en_father_rst,
                         input [2:0] press, // input
                         input [7:0] switch,
                         output reg [29:0] r_show_o,                // show
                         output reg [2:0] r_ram_ticket_operation_o, // ticket
                         output reg [31:0] r_ram_ticket_index_o,
                         input wire w_ram_ticket_over_i,
                         input wire w_ram_ticket_wrong_i,
                         input wire [31:0] w_ram_ticket_num_i,
                         input wire [64:0] w_ram_ticket_data_i,
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
    // .          F0
    // .       /  |  \
    // .      F1  F2  F3
    // .          F4
    
    parameter F0 = 3'b000;
    parameter F1 = 3'b001;
    parameter F2 = 3'b010;
    parameter F3 = 3'b011;
    parameter F4 = 3'b100;
    
    reg [2:0] present_state;
    reg [2:0] next_state;
    
    // ----------
    
    reg F1_end;
    reg F3_end;
    reg F4_end;
    reg change_ticket;
    integer income;
    wire [19:0] income_out;
    
    integer index;
    reg [9:0] ticket_id;
    reg [4:0] ticket_movie;
    reg [14:0] ticket_session;
    reg [9:0] ticket_buy_time;
    reg [9:0] ticket_price;
    reg [1:0] ticket_state;
    reg [9:0] ticket_seat;
    reg [9:0] movie_id;
    reg use_vip;
    reg begin_sum;
    
    // ----------
    
    // time div
    integer count;
    parameter PERIOD = 200_000_000;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end
        else begin
            if (!en) begin
                count <= 0;
            end
            else begin
                if (count == PERIOD - 1) begin
                    count <= 0;
                end
                else begin
                    count <= count + 1;
                end
            end
        end
    end
    
    // ----------
    
    // state change
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= F0;
        end
        else begin
            if (!en) begin
                present_state <= F0;
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
        end
        else begin
            if (!en) begin
                en_father_rst <= 0;
            end
            else begin
                case(present_state)
                    F0:
                    case(press)
                        con:
                        begin
                            case(switch)
                                8'b0000_0001: next_state <= F1;
                                8'b0000_0010: next_state <= F2;
                                8'b0000_0100: next_state <= F3;
                                default:;
                            endcase
                        end
                        rls: en_father_rst <= 1;
                        default:;
                    endcase
                    
                    F1:
                    case(press)
                        rls: next_state <= F0;
                        ris: next_state <= F0;
                        default:;
                    endcase
                    
                    F2:
                    case(press)
                        con: next_state <= F4;
                        rls: next_state <= F0;
                        ris: next_state <= F0;
                        default:;
                    endcase
                    
                    F3:
                    case(press)
                        con: next_state <= F0;
                        rls: next_state <= F0;
                        ris: next_state <= F0;
                        default:;
                    endcase
                    
                    F4:
                    case(press)
                        con: next_state <= F0;
                        rls: next_state <= F0;
                        ris: next_state <= F0;
                        default:;
                    endcase
                endcase
            end
        end
    end
    
    wire [29:0] out1 = {ticket_id,ticket_movie,ticket_session};
    wire [29:0] out2 = {ticket_buy_time,ticket_price,3'b000,ticket_state,use_vip};
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            F1_end                   <= 0;
            F3_end                   <= 0;
            F4_end                   <= 0;
            change_ticket            <= 0;
            income                   <= 'b0;
            index                    <= 1;
            ticket_id                <= 'b0;
            ticket_movie             <= 'b0;
            ticket_session           <= 'b0;
            ticket_buy_time          <= 'b0;
            ticket_price             <= 'b0;
            ticket_state             <= 'b0;
            ticket_seat              <= 'b0;
            movie_id                 <= 'b0;
            use_vip                  <= 'b0;
            begin_sum                <= 'b0;
            r_show_o                 <= 'bz;
            r_ram_ticket_operation_o <= 'bz;
            r_ram_ticket_index_o     <= 'bz;
        end
        else begin
            if (!en) begin
                F1_end                   <= 0;
                F3_end                   <= 0;
                F4_end                   <= 0;
                change_ticket            <= 0;
                income                   <= 'b0;
                index                    <= 1;
                ticket_id                <= 'b0;
                ticket_movie             <= 'b0;
                ticket_session           <= 'b0;
                ticket_buy_time          <= 'b0;
                ticket_price             <= 'b0;
                ticket_state             <= 'b0;
                ticket_seat              <= 'b0;
                movie_id                 <= 'b0;
                use_vip                  <= 'b0;
                begin_sum                <= 'b0;
                r_show_o                 <= 'bz;
                r_ram_ticket_operation_o <= 'bz;
                r_ram_ticket_index_o     <= 'bz;
            end
            else begin
                case(present_state)
                    F0:
                    begin
                        F1_end                   <= 0;
                        F3_end                   <= 0;
                        F4_end                   <= 0;
                        index                    <= 1;
                        r_ram_ticket_operation_o <= 0;
                        r_show_o                 <= {t,i,c,blank,blank,blank};
                    end
                    
                    F1:
                    begin
                        F3_end <= 0;
                        F4_end <= 0;
                        if (F1_end == 0) begin
                            change_ticket <= 1;
                            r_show_o      <= {blank,blank,blank,blank,blank,blank};
                            F1_end        <= 1;
                        end
                        
                        if (w_ram_ticket_num_i == 0) begin
                            r_show_o <= {blank,n,o,n,e,blank};
                        end
                        else begin
                            if (count == PERIOD - 1) begin
                                if (r_show_o == out1)begin
                                    r_show_o <= out2;
                                end
                                else begin
                                    r_show_o <= out1;
                                end
                            end
                            else begin
                                ;
                            end
                        end
                        
                        case(press)
                            nxt:
                            begin
                                if (index == w_ram_ticket_num_i) begin
                                    index <= index;
                                end
                                else begin
                                    index         <= index + 1;
                                    change_ticket <= 1;
                                end
                            end
                            del:
                            begin
                                if (index == 1) begin
                                    index <= index;
                                end
                                else begin
                                    index         <= index - 1;
                                    change_ticket <= 1;
                                end
                            end
                            rls: index <= 1;
                            ris: index <= 1;
                            default:;
                        endcase
                        
                        if (change_ticket == 1) begin
                            r_ram_ticket_operation_o <= read_by_index;
                            r_ram_ticket_index_o     <= index;
                            if (w_ram_ticket_over_i) begin
                                ticket_id       <= {2'b00,w_ram_ticket_data_i[64:62],2'b00,w_ram_ticket_data_i[61:59]};
                                ticket_movie    <= w_ram_ticket_data_i[58:54];
                                ticket_session  <= w_ram_ticket_data_i[53:39];
                                ticket_buy_time <= w_ram_ticket_data_i[38:29];
                                ticket_price    <= w_ram_ticket_data_i[28:19];
                                ticket_state    <= w_ram_ticket_data_i[18:17];
                                ticket_seat     <= w_ram_ticket_data_i[16:7];
                                movie_id        <= w_ram_ticket_data_i[6:1];
                                if (w_ram_ticket_data_i[0] == 1) begin
                                    use_vip <= v;
                                end
                                else begin
                                    use_vip <= blank;
                                end
                                change_ticket <= 0;
                            end
                        end
                        if (change_ticket == 0) begin
                            r_ram_ticket_operation_o <= idle;
                        end
                    end
                    
                    F2:
                    begin
                        F1_end   <= 0;
                        F3_end   <= 0;
                        F4_end   <= 0;
                        r_show_o <= {c,l,e,a,r,5'd29};
                    end
                    
                    F3:
                    begin
                        F1_end   <= 0;
                        F4_end   <= 0;
                        r_show_o <= {i,n,income_out};
                        if (F3_end == 0) begin
                            if (w_ram_ticket_over_i == 0) begin
                                r_ram_ticket_operation_o <= read_by_index;
                                r_ram_ticket_index_o     <= index;
                                index                    <= index + 1;
                                begin_sum                <= 1;
                            end
                            else begin
                                if (w_ram_ticket_wrong_i == 0) begin
                                    if (begin_sum == 1) begin
                                        r_ram_ticket_operation_o <= idle;
                                        income                   <= income + w_ram_ticket_data_i[28:24] * 10 + w_ram_ticket_data_i[23:19]; // MATH
                                        begin_sum                <= 0;
                                    end
                                end
                                else begin
                                    F3_end <= 1;
                                end
                            end
                        end
                        else begin
                            r_ram_ticket_operation_o <= idle;
                            begin_sum                <= 0;
                        end
                    end
                    
                    F4:
                    begin
                        F1_end   <= 0;
                        F3_end   <= 0;
                        r_show_o <= {5'd6,5'd6,5'd6,5'd6,5'd6,5'd6};
                        if (F4_end == 0) begin
                            r_ram_ticket_operation_o <= clear_all;
                            if (w_ram_ticket_over_i == 1) begin
                                F4_end <= 1;
                            end
                        end
                        else begin
                            r_ram_ticket_operation_o <= idle;
                        end
                    end
                endcase
            end
        end
    end
    
    binary_to_08421 u_binary_to_08421_mc
    (
    .in(income),
    .out(income_out)
    );
    
endmodule
