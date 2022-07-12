module client_b_refund (input clk,
                        input rst_n,
                        input en,
                        output reg en_father_rst,
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
                        output reg [5:0] r_ram_movie_id_o,
                        input wire [45:0] w_ram_movie_data_i,
                        output reg [45:0] r_ram_movie_data_o,
                        output reg [2:0] r_ram_ticket_operation_o, // ticket
                        output reg [31:0] r_ram_ticket_index_o,
                        input wire w_ram_ticket_over_i,
                        input wire w_ram_ticket_wrong_i,
                        input wire [31:0] w_ram_ticket_num_i,
                        output reg [5:0] r_ram_ticket_id_o,
                        input wire [64:0] w_ram_ticket_data_i,
                        output reg [64:0] r_ram_ticket_data_o,
                        output reg [1:0] r_wr_ram_vip_o, // vip
                        output reg [1:0] r_vip_o,
                        output reg [4:0] r_vip_movie_number_o,
                        output reg [31:0] r_vip_cost_o,
                        output reg [31:0] r_vip_save_o,
                        output reg [19:0] r_vip_password_o,
                        output reg [2:0] r_vip_day_o,
                        output reg [4:0] r_vip_off_o,
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
    // .    B0
    // .    B1
    // .  /    \
    // . B2    B3
    parameter B0 = 2'b00;
    parameter B1 = 2'b01;
    parameter B2 = 2'b10;
    parameter B3 = 2'b11;
    
    reg [1:0] present_state;
    reg [1:0] next_state;
    
    // ----------
    
    integer index;
    reg [9:0] ticket_id;
    reg [4:0] ticket_movie;
    reg [14:0] ticket_session;
    reg [9:0] ticket_buy_time;
    reg [9:0] ticket_price;
    reg [1:0] ticket_state;
    reg [9:0] ticket_seat;
    reg [9:0] movie_id;
    reg [4:0] use_vip;
    
    reg [64:0] data_ticket;
    
    reg [45:0] data_movie;
    reg [9:0] movie_rest_ticket;
    reg [3:0] movie_seat;
    reg [9:0] movie_price;
    
    reg B0_end;
    reg B1_end;
    reg wrong;
    reg B2_end;
    reg change_ticket;
    
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
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= B0;
        end
        else begin
            if (!en) begin
                present_state <= B0;
            end
            else begin
                present_state <= next_state;
            end
        end
    end
    
    // get next state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state    <= B0;
            en_father_rst <= 0;
        end
        else begin
            if (!en) begin
                next_state    <= B0;
                en_father_rst <= 0;
            end
            else begin
                case(present_state)
                    B0:
                    begin
                        case(press)
                            con: next_state    <= B1;
                            rls: en_father_rst <= 1;
                            default:;
                        endcase
                    end
                    
                    B1:
                    begin
                        if (B1_end == 1 && con==press) begin
                            if (wrong == 1) begin
                                next_state <= B3;
                            end
                            else begin
                                next_state <= B2;
                            end
                        end
                        else begin
                            case(press)
                                rls: next_state <= B0;
                                ris: next_state <= B0;
                                default:;
                            endcase
                        end
                    end
                    
                    B2:
                    begin
                        if (B2_end == 1) begin
                            case(press)
                                con: next_state <= B0;
                                rls: next_state <= B0;
                                ris: next_state <= B0;
                                default:;
                            endcase
                        end
                        else begin
                            case(press)
                                ris: next_state <= B0;
                                default:;
                            endcase
                        end
                    end
                    
                    B3:
                    begin
                        case(press)
                            con: next_state <= B0;
                            rls: next_state <= B0;
                            ris: next_state <= B0;
                            default:;
                        endcase
                    end
                endcase
            end
        end
    end
    
    wire [29:0] out1 = {ticket_id,ticket_movie,ticket_session};
    wire [29:0] out2 = {ticket_buy_time,ticket_price,3'b000,ticket_state,use_vip};
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
            data_ticket              <= 'b0;
            data_movie               <= 'b0;
            movie_rest_ticket        <= 'b0;
            movie_seat               <= 'b0;
            movie_price              <= 'b0;
            B0_end                   <= 0;
            B1_end                   <= 0;
            wrong                    <= 0;
            B2_end                   <= 0;
            change_ticket            <= 0;
            r_target_count_o         <= 'bz;
            r_en_array_o             <= 'bz;
            r_show_o                 <= 'bz;
            r_ram_movie_operation_o  <= 'bz;
            r_ram_movie_index_o      <= 'bz;
            r_ram_movie_id_o         <= 'bz;
            r_ram_movie_data_o       <= 'bz;
            r_ram_ticket_operation_o <= 'bz;
            r_ram_ticket_index_o     <= 'bz;
            r_ram_ticket_id_o        <= 'bz;
            r_ram_ticket_data_o      <= 'bz;
            r_wr_ram_vip_o           <= 'bz;
            r_vip_o                  <= 'bz;
            r_vip_movie_number_o     <= 'bz;
            r_vip_cost_o             <= 'bz;
            r_vip_save_o             <= 'bz;
            r_vip_password_o         <= 'bz;
            r_vip_day_o              <= 'bz;
            r_vip_off_o              <= 'bz;
        end
        else begin
            if (!en) begin
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
                data_ticket              <= 'b0;
                data_movie               <= 'b0;
                movie_rest_ticket        <= 'b0;
                movie_seat               <= 'b0;
                movie_price              <= 'b0;
                B0_end                   <= 0;
                B1_end                   <= 0;
                wrong                    <= 0;
                B2_end                   <= 0;
                change_ticket            <= 0;
                r_target_count_o         <= 'bz;
                r_en_array_o             <= 'bz;
                r_show_o                 <= 'bz;
                r_ram_movie_operation_o  <= 'bz;
                r_ram_movie_index_o      <= 'bz;
                r_ram_movie_id_o         <= 'bz;
                r_ram_movie_data_o       <= 'bz;
                r_ram_ticket_operation_o <= 'bz;
                r_ram_ticket_index_o     <= 'bz;
                r_ram_ticket_id_o        <= 'bz;
                r_ram_ticket_data_o      <= 'bz;
                r_wr_ram_vip_o           <= 'bz;
                r_vip_o                  <= 'bz;
                r_vip_movie_number_o     <= 'bz;
                r_vip_cost_o             <= 'bz;
                r_vip_save_o             <= 'bz;
                r_vip_password_o         <= 'bz;
                r_vip_day_o              <= 'bz;
                r_vip_off_o              <= 'bz;
            end
            else begin
                case(present_state)
                    B0:
                    begin
                        B1_end                   <= 0;
                        wrong                    <= 0;
                        B2_end                   <= 0;
                        r_en_array_o             <= 0;
                        r_ram_movie_operation_o  <= idle;
                        r_ram_ticket_operation_o <= idle;
                        r_wr_ram_vip_o           <= 2'b00;
                        
                        if (B0_end == 0) begin
                            change_ticket <= 1;
                            r_show_o      <= {blank,blank,blank,blank,blank,blank};
                            B0_end        <= 1;
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
                    
                    B1:
                    begin
                        B0_end <= 0;
                        B2_end <= 0;
                        if (B1_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 2;
                            r_show_o         <= {i,d,blank,blank,blank,blank};
                            
                            if (w_over_array_i == 1) begin
                                r_ram_ticket_operation_o <= read_by_id;
                                r_ram_ticket_id_o        <= {w_array_input_i[17:15],w_array_input_i[12:10]};
                            end
                            
                            if (w_ram_ticket_over_i == 1) begin
                                if (w_ram_ticket_wrong_i == 0 && w_ram_ticket_data_i[18:17] == 2'b00) begin
                                    wrong                   <= 0;
                                    data_ticket             <= w_ram_ticket_data_i;
                                    r_ram_movie_operation_o <= read_by_id;
                                    r_ram_movie_id_o        <= w_ram_ticket_data_i[6:1];
                                end
                                else begin
                                    wrong  <= 1;
                                    B1_end <= 1;
                                end
                            end
                            
                            if (w_ram_movie_over_i == 1) begin
                                data_movie        <= w_ram_movie_data_i;
                                movie_price       <= w_ram_movie_data_i[34:25];
                                movie_rest_ticket <= w_ram_movie_data_i[9:5] + 5'b00001; // MATH
                                movie_seat        <= 4'b0000;                            // wrong!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                                B1_end            <= 1;
                            end
                        end
                        else begin
                            r_en_array_o             <= 0;
                            r_ram_ticket_operation_o <= idle;
                            r_ram_movie_operation_o  <= idle;
                            
                            r_ram_ticket_id_o    <= data_ticket[64:59];
                            r_ram_ticket_data_o  <= {data_ticket[64:19],2'b10,data_ticket[16:0]};
                            r_ram_movie_id_o     <= data_movie[45:40];
                            r_ram_movie_data_o   <= {data_movie[45:10],movie_rest_ticket,movie_seat,1'b1};
                            r_vip_o              <= w_vip_i;
                            r_vip_movie_number_o <= w_vip_movie_number_i - 5'b00001;
                            r_vip_cost_o         <= w_vip_cost_i - (ticket_price[9:5] * 10 + ticket_price[4:0]);                                                // MATH
                            r_vip_save_o         <= w_vip_save_i - ((movie_price[9:5] * 10 + movie_price[4:0]) - (ticket_price[9:5] * 10 + ticket_price[4:0])); // MATH
                            r_vip_password_o     <= w_vip_password_i;
                            r_vip_day_o          <= w_vip_day_i;
                        end
                    end
                    
                    B2:
                    begin
                        B0_end   <= 0;
                        B1_end   <= 0;
                        wrong    <= 0;
                        r_show_o <= {blank,blank,ticket_price,blank,blank};
                        
                        
                        if (B2_end == 0) begin
                            r_ram_ticket_operation_o <= change_by_id;
                            r_ram_movie_operation_o  <= change_by_id;
                            if (use_vip == v) begin
                                r_wr_ram_vip_o <= 2'b10;
                            end
                            else begin
                                ;
                            end
                            
                            if (w_ram_movie_over_i == 1 && w_ram_ticket_over_i == 1) begin
                                B2_end <= 1;
                            end
                        end
                        else begin
                            r_ram_ticket_operation_o <= idle;
                            r_ram_movie_operation_o  <= idle;
                            r_wr_ram_vip_o           <= 2'b00;
                        end
                    end
                    
                    B3:
                    begin
                        B0_end   <= 0;
                        B1_end   <= 0;
                        wrong    <= 0;
                        B2_end   <= 0;
                        r_show_o <= {blank,e,r,r,o,r};
                    end
                endcase
            end
        end
    end
endmodule // client_b_refund
