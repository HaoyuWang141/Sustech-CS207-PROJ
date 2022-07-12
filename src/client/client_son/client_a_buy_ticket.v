`include "vip_price.v"
module client_a_buy_ticket (input clk,
                            input rst_n,
                            input en,
                            output reg en_father_rst,
                            input wire [9:0] w_cinema_time_i,
                            input [2:0] press, // input
                            input [7:0] switch,
                            output reg [3:0] r_target_count_o,
                            output reg r_en_array_o,
                            input wire w_over_array_i,
                            input wire [19:0] w_array_input_i,
                            output reg [29:0] r_show_o,               // show
                            output reg [2:0] r_ram_movie_operation_o, // movie
                            output reg [31:0] r_ram_movie_index_o,
                            input wire w_ram_movie_over_i,
                            input wire [31:0] w_ram_movie_num_i,
                            output reg [5:0] r_ram_movie_id_o,
                            input wire [45:0] w_ram_movie_data_i,
                            output reg [45:0] r_ram_movie_data_o,
                            output reg [2:0] r_ram_ticket_operation_o, // ticket
                            output reg [31:0] r_ram_ticket_index_o,
                            input wire w_ram_ticket_over_i,
                            input wire [5:0] w_ram_ticket_id_i,
                            output reg [64:0] r_ram_ticket_data_o,
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
    // .             A0 A0_error
    // .             A2
    // .             A3
    // .           /    \
    // .          A4     \
    // . A5_error A5 ---> A6 A7 A8
    parameter A0       = 4'b0000;
    parameter A5_error = 4'b0001; // 删了A1添了个A5_error，所以直接扔这里图个方便
    parameter A2       = 4'b0010;
    parameter A3       = 4'b0011;
    parameter A0_error = 4'b0100;
    parameter A5       = 4'b0101;
    parameter A6       = 4'b0110;
    parameter A7       = 4'b0111;
    parameter A8       = 4'b1000;
    
    reg [3:0] present_state;
    reg [3:0] next_state;
    
    // ----------
    
    integer index; // the index for movie, the range is from 1 to w_ram_movie_num_i
    reg [9:0] movie_id;
    reg [4:0] movie_name;
    reg [9:0] movie_price;
    reg [14:0] movie_session;
    reg [4:0] movie_rest_ticket;
    reg [3:0] movie_seat;
    
    reg [9:0] ticket_seat;
    reg [9:0] ticket_id;
    reg use_vip;
    
    wire [9:0] ticket_price_vip;
    wire [31:0] ticket_price_vip_integer;
    wire [9:0] save_money_vip;
    wire [31:0] save_money_vip_integer;
    
    reg A0_end;
    reg A5_end;
    reg A6_end;
    reg change_movie;
    reg [9:0] can_use_vip;
    
    // ----------
    
    // time div. It is used to implement roll movie information.
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
            present_state <= A0;
        end
        else begin
            if (!en) begin
                present_state <= A0;
            end
            else begin
                present_state <= next_state;
            end
        end
    end
    
    // get next state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state    <= A0;
            en_father_rst <= 0;
        end
        else begin
            if (!en)begin
                next_state    <= A0;
                en_father_rst <= 0;
            end
            else begin
                case(present_state)
                    A0:
                    case(press)
                        con:
                        begin
                            if (movie_rest_ticket > 0) begin
                                next_state <= A2;
                            end
                            else begin
                                next_state <= A0_error;
                            end
                        end
                        rls: en_father_rst <= 1;
                        default:;
                    endcase
                    
                    A0_error:
                    case(press)
                        con: next_state <= A0;
                        rls: next_state <= A0;
                        default:;
                    endcase
                    
                    A2:
                    case(press)
                        con:
                        begin
                            if (can_use_vip == {y,v}) begin
                                next_state <= A3;
                            end
                            else begin
                                next_state <= A6;
                            end
                        end
                        rls: next_state <= A0;
                        ris: next_state <= A0;
                        default:;
                    endcase
                    
                    A3:
                    case(press)
                        con:
                        begin
                            case(switch)
                                8'b0000_0001: next_state <= A6;
                                8'b0000_0010: next_state <= A5;
                            endcase
                        end
                        rls: next_state <= A2;
                        ris: next_state <= A0;
                        default:;
                    endcase
                    
                    A5:
                    begin
                        if (A5_end == 1) begin
                            if (use_vip == 1) begin
                                next_state <= A6;
                            end
                            else begin
                                next_state <= A5_error;
                            end
                        end
                        else begin
                            case(press)
                                rls: next_state <= A3;
                                ris: next_state <= A0;
                                default:;
                            endcase
                        end
                    end
                    
                    A5_error:
                    case(press)
                        con: next_state <= A5;
                        rls: next_state <= A3;
                        ris: next_state <= A0;
                        default:;
                    endcase
                    
                    A6:
                    begin
                        if (A6_end == 1) begin
                            next_state <= A7;
                        end
                        else begin
                            case(press)
                                rls: next_state <= A0;
                                ris: next_state <= A0;
                                default:;
                            endcase
                        end
                    end
                    
                    A7:
                    case(press)
                        con: next_state <= A0;
                        rls: next_state <= A0;
                        ris: next_state <= A0;
                        default:;
                    endcase
                endcase
            end
        end
    end
    
    wire [29:0] out1 = {movie_id,movie_name,movie_session};
    wire [29:0] out2 = {movie_price,blank,movie_rest_ticket,can_use_vip};
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index                    <= 1;
            movie_id                 <= 'b0;
            movie_name               <= 'b0;
            movie_price              <= 'b0;
            movie_session            <= 'b0;
            movie_rest_ticket        <= 'b0;
            movie_seat               <= 'b0;
            ticket_seat              <= 'b0;
            ticket_id                <= 'b0;
            use_vip                  <= 0;
            A0_end                   <= 0;
            A5_end                   <= 0;
            A6_end                   <= 0;
            change_movie             <= 0;
            can_use_vip              <= {blank,blank};
            r_target_count_o         <= 'bz;
            r_en_array_o             <= 'bz;
            r_show_o                 <= 'bz;
            r_ram_movie_operation_o  <= 'bz;
            r_ram_movie_index_o      <= 'bz;
            r_ram_ticket_operation_o <= 'bz;
            r_ram_ticket_index_o     <= 'bz;
            r_wr_ram_vip_o           <= 'bz;
            r_vip_o                  <= 'bz;
            r_vip_movie_number_o     <= 'bz;
            r_vip_cost_o             <= 'bz;
            r_vip_save_o             <= 'bz;
            r_vip_password_o         <= 'bz;
            r_vip_day_o              <= 'bz;
            r_ram_movie_id_o         <= 'bz;
            r_ram_movie_data_o       <= 'bz;
            r_ram_ticket_data_o      <= 'bz;
        end
        else begin
            if (!en) begin
                index                    <= 1;
                movie_id                 <= 'b0;
                movie_name               <= 'b0;
                movie_price              <= 'b0;
                movie_session            <= 'b0;
                movie_rest_ticket        <= 'b0;
                movie_seat               <= 'b0;
                ticket_seat              <= 'b0;
                ticket_id                <= 'b0;
                use_vip                  <= 0;
                A0_end                   <= 0;
                A5_end                   <= 0;
                A6_end                   <= 0;
                change_movie             <= 0;
                can_use_vip              <= {blank,blank};
                r_target_count_o         <= 'bz;
                r_en_array_o             <= 'bz;
                r_show_o                 <= 'bz;
                r_ram_movie_operation_o  <= 'bz;
                r_ram_movie_index_o      <= 'bz;
                r_ram_ticket_operation_o <= 'bz;
                r_ram_ticket_index_o     <= 'bz;
                r_wr_ram_vip_o           <= 'bz;
                r_vip_o                  <= 'bz;
                r_vip_movie_number_o     <= 'bz;
                r_vip_cost_o             <= 'bz;
                r_vip_save_o             <= 'bz;
                r_vip_password_o         <= 'bz;
                r_vip_day_o              <= 'bz;
                r_ram_movie_id_o         <= 'bz;
                r_ram_movie_data_o       <= 'bz;
                r_ram_ticket_data_o      <= 'bz;
            end
            else begin
                case(present_state)
                    A0:
                    begin
                        A5_end                   <= 0;
                        A6_end                   <= 0;
                        r_en_array_o             <= 0;
                        r_ram_ticket_operation_o <= idle;
                        r_wr_ram_vip_o           <= 2'b00;
                        
                        if (A0_end == 0) begin
                            change_movie <= 1;
                            r_show_o     <= {blank,blank,blank,blank,blank,blank};
                            A0_end       <= 1;
                        end
                        else begin
                            ;
                        end
                        
                        if (w_ram_movie_num_i == 0) begin
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
                                if (index == w_ram_movie_num_i) begin
                                    index <= index;
                                end
                                else begin
                                    index        <= index + 1;
                                    change_movie <= 1;
                                end
                            end
                            del:
                            begin
                                if (index == 1) begin
                                    index <= index;
                                end
                                else begin
                                    index        <= index - 1;
                                    change_movie <= 1;
                                end
                            end
                            default:;
                        endcase
                        
                        if (change_movie == 1) begin
                            if (w_ram_movie_over_i == 0) begin
                                r_ram_movie_operation_o <= read_by_index;
                                r_ram_movie_index_o     <= index;
                            end
                            else begin
                                movie_id          <= {2'b00,w_ram_movie_data_i[45:43],2'b00,w_ram_movie_data_i[42:40]};
                                movie_name        <= w_ram_movie_data_i[39:35];
                                movie_price       <= w_ram_movie_data_i[34:25];
                                movie_session     <= w_ram_movie_data_i[24:10];
                                movie_rest_ticket <= w_ram_movie_data_i[9:5];
                                movie_seat        <= w_ram_movie_data_i[4:1];
                                change_movie      <= 0;
                                if (w_vip_i == 2'b11 && w_vip_day_i == w_ram_movie_data_i[22:20]) begin
                                    can_use_vip <= {y,v};
                                end
                                else begin
                                    can_use_vip <= {n,v};
                                end
                            end
                        end
                        else begin
                            r_ram_movie_operation_o <= idle;
                        end
                    end
                    
                    A0_error:
                    begin
                        A0_end   <= 0;
                        A5_end   <= 0;
                        A6_end   <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                    
                    A2:
                    begin
                        A0_end   <= 0;
                        A5_end   <= 0;
                        A6_end   <= 0;
                        r_show_o <= {blank,blank,blank,blank,blank,blank};
                    end // wrong !!!!!!!!!!!!!!!!!!!!!!!!!
                    
                    A3:
                    begin
                        A0_end   <= 0;
                        A5_end   <= 0;
                        A6_end   <= 0;
                        r_show_o <= {blank,blank,v,i,p,5'd29};
                    end
                    
                    A5:
                    begin
                        A0_end <= 0;
                        A6_end <= 0;
                        if (A5_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 4;
                            r_show_o         <= {p,blank,20'bz};
                            if (w_over_array_i == 1) begin
                                A5_end <= 1;
                                if (w_array_input_i == w_vip_password_i) begin
                                    use_vip <= 1;
                                end
                                else begin
                                    use_vip <= 0;
                                end
                            end
                            else begin
                                ;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    A5_error:
                    begin
                        A0_end   <= 0;
                        A5_end   <= 0;
                        A6_end   <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                    
                    A6:
                    begin
                        A0_end <= 0;
                        A5_end <= 0;
                        
                        if (use_vip == 1) begin
                            r_show_o <= {movie_name,movie_session,ticket_price_vip};
                            
                            r_ram_ticket_data_o <= {6'b0,movie_name,movie_session,w_cinema_time_i,ticket_price_vip,2'b00,ticket_seat,movie_id[7:5],movie_id[2:0],1'b1};
                            r_ram_movie_id_o    <= {movie_id[7:5],movie_id[2:0]};
                            r_ram_movie_data_o  <= {movie_id[7:5],movie_id[2:0],movie_name,movie_price,movie_session,movie_rest_ticket-5'd1,movie_seat,1'b1};
                            
                            r_vip_o              <= w_vip_i;
                            r_vip_movie_number_o <= w_vip_movie_number_i + 5'b00001;         // MATH
                            r_vip_cost_o         <= w_vip_cost_i + ticket_price_vip_integer; // MATH
                            r_vip_save_o         <= w_vip_save_i + save_money_vip_integer;   // MATH
                            r_vip_password_o     <= w_vip_password_i;
                            r_vip_day_o          <= w_vip_day_i;
                        end
                        else begin
                            r_show_o <= {movie_name,movie_session,movie_price};
                            
                            r_ram_ticket_data_o <= {6'b0,movie_name,movie_session,w_cinema_time_i,movie_price,2'b00,ticket_seat,movie_id[7:5],movie_id[2:0],1'b0};
                            r_ram_movie_id_o    <= {movie_id[7:5],movie_id[2:0]};
                            r_ram_movie_data_o  <= {movie_id[7:5],movie_id[2:0],movie_name,movie_price,movie_session,movie_rest_ticket-5'd1,movie_seat,1'b1};
                        end
                        
                        if (A6_end == 0) begin
                            if (press == con) begin
                                r_ram_ticket_operation_o <= new;
                                r_ram_movie_operation_o  <= change_by_id;
                                if (use_vip == 1) begin
                                    r_wr_ram_vip_o <= 2'b10;
                                end
                                else begin
                                    ;
                                end
                            end
                            else begin
                                ;
                            end
                            
                            if (w_ram_movie_over_i == 1 && w_ram_ticket_over_i == 1) begin
                                ticket_id <= {2'b00,w_ram_ticket_id_i[5:3],2'b00,w_ram_ticket_id_i[2:0]};
                                A6_end    <= 1;
                            end
                        end
                        else begin
                            r_ram_movie_operation_o  <= idle;
                            r_ram_ticket_operation_o <= idle;
                            r_wr_ram_vip_o           <= 2'b00;
                        end
                    end
                    
                    A7:
                    begin
                        A0_end   <= 0;
                        A5_end   <= 0;
                        A6_end   <= 0;
                        r_show_o <= {blank,i,d,blank,ticket_id};
                    end
                    
                endcase
            end
        end
    end
    
    vip_price u_vip_price
    (
    .movie_price(movie_price),
    .vip_off(w_vip_off_i),
    .ticket_price_integer(ticket_price_vip_integer),
    .save_money_integer(save_money_vip_integer),
    .ticket_price(ticket_price_vip),
    .save_money(save_money_vip)
    );
endmodule // client_buy_ticket
