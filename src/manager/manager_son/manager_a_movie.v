module manager_a_movie (input clk,
                        input rst_n,
                        input en,
                        output reg en_father_rst,
                        input [2:0] press, // input
                        input [7:0] switch,
                        output reg [3:0] r_target_count_o,
                        output reg r_en_array_o,
                        input wire w_over_array_i,
                        input wire [19:0] w_array_input_i,
                        output reg [29:0] r_show_o,
                        output reg [2:0] r_ram_movie_operation_o, // movie
                        output reg [31:0] r_ram_movie_index_o,
                        input wire w_ram_movie_over_i,
                        input wire [31:0] w_ram_movie_num_i,
                        output reg [5:0] r_ram_movie_id_o,
                        input wire [45:0] w_ram_movie_data_i,
                        output reg [45:0] r_ram_movie_data_o,
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
    // .        D0
    // .      /    \
    // .    D2      D6
    // .    D3      D7
    // .    D5    /    \
    // .    D1   / |  | \
    // .       D8 D9 D10 D11
    
    parameter D0    = 4'b0000;
    parameter D1    = 4'b0001;
    parameter D2    = 4'b0010;
    parameter D3    = 4'b0011;
    // parameter D4 = 4'b0100;
    parameter D5    = 4'b0101;
    parameter D6    = 4'b0110;
    parameter D7    = 4'b0111;
    parameter D8    = 4'b1000;
    parameter D9    = 4'b1001;
    parameter D10   = 4'b1010;
    parameter D11   = 4'b1011;
    
    reg [3:0] present_state;
    reg [3:0] next_state;
    
    // ----------
    
    integer index;
    reg D1_end;
    reg D2_end;
    reg D3_end;
    reg D5_end;
    reg D6_end;
    reg D7_end;
    reg D8_end;
    reg D9_end;
    reg D10_end;
    reg D11_end;
    reg [9:0] movie_id;
    reg [4:0] movie_name;
    reg [9:0] movie_price;
    reg [14:0] movie_session;
    reg [4:0] movie_rest_ticket;
    reg [3:0] movie_seat;
    reg change_movie;
    
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
    
    // state change
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= D0;
        end
        else begin
            if (!en) begin
                present_state <= D0;
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
            next_state    <= D0;
        end
        else begin
            if (!en) begin
                en_father_rst <= 0;
                next_state    <= D0;
            end
            else begin
                case(present_state)
                    D0:
                    case(press)
                        con:
                        begin
                            case(switch)
                                8'b0000_0001: next_state <= D2;
                                8'b0000_0010: next_state <= D6;
                                default:;
                            endcase
                        end
                        rls: en_father_rst <= 1;
                        default:;
                    endcase
                    
                    D2:
                    if (D2_end == 1) begin
                        next_state <= D3;
                    end
                    else begin
                        case(press)
                            ris: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D3:
                    if (D3_end == 1) begin
                        next_state <= D5;
                    end
                    else begin
                        case(press)
                            ris: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D5:
                    if (D5_end == 1) begin
                        next_state <= D1;
                    end
                    else begin
                        case(press)
                            ris: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D1:
                    if (D1_end == 1) begin
                        case(press)
                            con: next_state <= D0;
                            ris: next_state <= D0;
                            rls: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D6:
                    case(press)
                        con: next_state <= D7;
                        rls: next_state <= D0;
                        ris: next_state <= D0;
                        default:;
                    endcase
                    
                    D7:
                    case(press)
                        con:
                        case(switch)
                            8'b0000_0001: next_state <= D8;
                            8'b0000_0010: next_state <= D9;
                            8'b0000_0100: next_state <= D10;
                            8'b0000_1000: next_state <= D11;
                            default:;
                        endcase
                        rls: next_state <= D6;
                        ris: next_state <= D0;
                        default:;
                    endcase
                    
                    D8:
                    if (D8_end == 1) begin
                        next_state <= D7;
                    end
                    else begin
                        case(press)
                            rls: next_state <= D7;
                            ris: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D9:
                    if (D9_end == 1) begin
                        next_state <= D7;
                    end
                    else begin
                        case(press)
                            rls: next_state <= D7;
                            ris: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D10:
                    if (D10_end == 1) begin
                        next_state <= D7;
                    end
                    else begin
                        case(press)
                            rls: next_state <= D7;
                            ris: next_state <= D0;
                            default:;
                        endcase
                    end
                    
                    D11:
                    begin
                        if (D11_end == 1) begin
                            next_state <= D7;
                        end
                        else begin
                            case(press)
                                rls: next_state <= D7;
                                ris: next_state <= D7;
                                default:;
                            endcase
                        end
                    end
                endcase
            end
        end
    end
    
    wire [29:0] out1 = {movie_id,movie_name,movie_session};
    wire [29:0] out2 = {movie_price,4'b0,movie_seat[3],4'b0,movie_seat[2],4'b0,movie_seat[1],4'b0,movie_seat[0]};
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index                   <= 1;
            D1_end                  <= 0;
            D2_end                  <= 0;
            D3_end                  <= 0;
            D5_end                  <= 0;
            D6_end                  <= 0;
            D7_end                  <= 0;
            D8_end                  <= 0;
            D9_end                  <= 0;
            D10_end                 <= 0;
            D11_end                 <= 0;
            movie_id                <= 'b0;
            movie_name              <= 'b0;
            movie_price             <= 'b0;
            movie_session           <= 'b0;
            movie_rest_ticket       <= 'b0;
            movie_seat              <= 'b0;
            change_movie            <= 0;
            r_target_count_o        <= 'bz;
            r_en_array_o            <= 'bz;
            r_show_o                <= 'bz;
            r_ram_movie_operation_o <= 'bz;
            r_ram_movie_index_o     <= 'bz;
            r_ram_movie_id_o        <= 'bz;
            r_ram_movie_data_o      <= 'bz;
        end
        else begin
            if (!en) begin
                index                   <= 1;
                D1_end                  <= 0;
                D2_end                  <= 0;
                D3_end                  <= 0;
                D5_end                  <= 0;
                D6_end                  <= 0;
                D7_end                  <= 0;
                D8_end                  <= 0;
                D9_end                  <= 0;
                D10_end                 <= 0;
                D11_end                 <= 0;
                movie_id                <= 'b0;
                movie_name              <= 'b0;
                movie_price             <= 'b0;
                movie_session           <= 'b0;
                movie_rest_ticket       <= 'b0;
                movie_seat              <= 'b0;
                change_movie            <= 0;
                r_target_count_o        <= 'bz;
                r_en_array_o            <= 'bz;
                r_show_o                <= 'bz;
                r_ram_movie_operation_o <= 'bz;
                r_ram_movie_index_o     <= 'bz;
                r_ram_movie_id_o        <= 'bz;
                r_ram_movie_data_o      <= 'bz;
            end
            else begin
                case(present_state)
                    D0:
                    begin
                        D1_end                  <= 0;
                        D2_end                  <= 0;
                        D3_end                  <= 0;
                        D5_end                  <= 0;
                        D6_end                  <= 0;
                        D7_end                  <= 0;
                        D8_end                  <= 0;
                        D9_end                  <= 0;
                        D10_end                 <= 0;
                        D11_end                 <= 0;
                        r_en_array_o            <= 0;
                        r_ram_movie_operation_o <= idle;
                        r_show_o                <= {blank,m,o,v,i,e};
                    end
                    
                    D2:
                    begin
                        D1_end       <= 0;
                        D3_end       <= 0;
                        D5_end       <= 0;
                        D6_end       <= 0;
                        D7_end       <= 0;
                        D8_end       <= 0;
                        D9_end       <= 0;
                        D10_end      <= 0;
                        D11_end      <= 0;
                        r_en_array_o <= 0;
                        
                        if (D2_end == 0) begin
                            case(switch)
                                8'b0000_0001:
                                begin
                                    r_show_o <= {n,a,m,e,blank,a};
                                    if (press == con) begin
                                        movie_name <= a;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0000_0010:
                                begin
                                    r_show_o <= {n,a,m,e,blank,b};
                                    if (press == con) begin
                                        movie_name <= b;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0000_0100:
                                begin
                                    r_show_o <= {n,a,m,e,blank,c};
                                    if (press == con) begin
                                        movie_name <= c;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0000_1000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,d};
                                    if (press == con) begin
                                        movie_name <= d;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0001_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,e};
                                    if (press == con) begin
                                        movie_name <= e;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0010_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,f};
                                    if (press == con) begin
                                        movie_name <= f;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0100_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,g};
                                    if (press == con) begin
                                        movie_name <= g;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b1000_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,h};
                                    if (press == con) begin
                                        movie_name <= h;
                                        D2_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                default: r_show_o <= {n,a,m,e,blank,blank};
                            endcase
                        end
                    end
                    
                    D3:
                    begin
                        D1_end   <= 0;
                        D2_end   <= 0;
                        D5_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D8_end   <= 0;
                        D9_end   <= 0;
                        D10_end  <= 0;
                        D11_end  <= 0;
                        r_show_o <= {p,r,20'bz};
                        if (D3_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 2;
                            if (w_over_array_i == 1) begin
                                movie_price <= w_array_input_i[19:10];
                                D3_end      <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    D5:
                    begin
                        D1_end   <= 0;
                        D2_end   <= 0;
                        D3_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D8_end   <= 0;
                        D9_end   <= 0;
                        D10_end  <= 0;
                        D11_end  <= 0;
                        r_show_o <= {5'd5,e,20'bz};
                        if (D5_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 3;
                            if (w_over_array_i == 1) begin
                                movie_session <= w_array_input_i[19:5];
                                D5_end        <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    D1:
                    begin
                        D2_end   <= 0;
                        D3_end   <= 0;
                        D5_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D8_end   <= 0;
                        D9_end   <= 0;
                        D10_end  <= 0;
                        D11_end  <= 0;
                        r_show_o <= {6'd6,6'd6,6'd6,6'd6,6'd6,6'd6};
                        if (D1_end == 0) begin
                            r_ram_movie_operation_o <= new;
                            r_ram_movie_data_o      <= {6'bz,movie_name,movie_price,movie_session,5'd4,4'b0000,1'b1};
                            if (w_ram_movie_over_i == 1) begin
                                D1_end <= 1;
                            end
                        end
                        else begin
                            r_ram_movie_operation_o <= idle;
                        end
                    end
                    
                    D6:
                    begin
                        D1_end  <= 0;
                        D2_end  <= 0;
                        D3_end  <= 0;
                        D5_end  <= 0;
                        D7_end  <= 0;
                        D8_end  <= 0;
                        D9_end  <= 0;
                        D10_end <= 0;
                        D11_end <= 0;
                        
                        if (D6_end == 0) begin
                            change_movie <= 1;
                            r_show_o     <= {blank,blank,blank,blank,blank,blank};
                            D6_end       <= 1;
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
                        endcase
                        
                        if (change_movie == 1) begin
                            r_ram_movie_operation_o <= read_by_index;
                            r_ram_movie_index_o     <= index;
                            if (w_ram_movie_over_i) begin
                                movie_id          <= {2'b00,w_ram_movie_data_i[45:43],2'b00,w_ram_movie_data_i[42:40]};
                                movie_name        <= w_ram_movie_data_i[39:35];
                                movie_price       <= w_ram_movie_data_i[34:25];
                                movie_session     <= w_ram_movie_data_i[24:10];
                                movie_rest_ticket <= w_ram_movie_data_i[9:5];
                                movie_seat        <= w_ram_movie_data_i[4:1];
                                change_movie      <= 0;
                            end
                        end
                        if (change_movie == 0) begin
                            r_ram_movie_operation_o <= idle;
                        end
                    end
                    
                    D7:
                    begin
                        D1_end       <= 0;
                        D2_end       <= 0;
                        D3_end       <= 0;
                        D5_end       <= 0;
                        D6_end       <= 0;
                        D8_end       <= 0;
                        D9_end       <= 0;
                        D10_end      <= 0;
                        D11_end      <= 0;
                        r_en_array_o <= 0;
                        r_show_o     <= {u,blank,d,o,blank,5'd29};
                        
                        if (D7_end == 0) begin
                            r_ram_movie_operation_o <= change_by_id;
                            r_ram_movie_id_o        <= {movie_id[7:5],movie_id[2:0]};
                            r_ram_movie_data_o      <= {movie_id[7:5],movie_id[2:0],movie_name,movie_price,movie_session,movie_rest_ticket-5'd1,movie_seat,1'b1};
                            if (w_ram_movie_over_i == 1) begin
                                D7_end <= 1;
                            end
                            else begin
                                ;
                            end
                        end
                        else begin
                            r_ram_movie_operation_o <= idle;
                        end
                    end
                    
                    D8:
                    begin
                        D1_end   <= 0;
                        D2_end   <= 0;
                        D3_end   <= 0;
                        D5_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D9_end   <= 0;
                        D10_end  <= 0;
                        D11_end  <= 0;
                        r_show_o <= {n,a,m,e,blank,blank};
                        if (D8_end == 0) begin
                            case(switch)
                                8'b0000_0001:
                                begin
                                    r_show_o <= {n,a,m,e,blank,a};
                                    if (press == con) begin
                                        movie_name <= a;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0000_0010:
                                begin
                                    r_show_o <= {n,a,m,e,blank,b};
                                    if (press == con) begin
                                        movie_name <= b;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0000_0100:
                                begin
                                    r_show_o <= {n,a,m,e,blank,c};
                                    if (press == con) begin
                                        movie_name <= c;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0000_1000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,d};
                                    if (press == con) begin
                                        movie_name <= d;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0001_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,e};
                                    if (press == con) begin
                                        movie_name <= e;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0010_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,f};
                                    if (press == con) begin
                                        movie_name <= f;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b0100_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,g};
                                    if (press == con) begin
                                        movie_name <= g;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                8'b1000_0000:
                                begin
                                    r_show_o <= {n,a,m,e,blank,h};
                                    if (press == con) begin
                                        movie_name <= h;
                                        D8_end     <= 1;
                                    end
                                    else begin
                                        ;
                                    end
                                end
                                default: r_show_o <= {n,a,m,e,blank,blank};
                            endcase
                        end
                    end
                    
                    D9:
                    begin
                        D1_end   <= 0;
                        D2_end   <= 0;
                        D3_end   <= 0;
                        D5_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D8_end   <= 0;
                        D10_end  <= 0;
                        D11_end  <= 0;
                        r_show_o <= {p,r,20'bz};
                        if (D9_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 2;
                            if (w_over_array_i == 1) begin
                                movie_price <= w_array_input_i[19:10];
                                D9_end      <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    D10:
                    begin
                        D1_end   <= 0;
                        D2_end   <= 0;
                        D3_end   <= 0;
                        D5_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D8_end   <= 0;
                        D9_end   <= 0;
                        D11_end  <= 0;
                        r_show_o <= {5'd5,e,20'bz};
                        if (D10_end == 0) begin
                            r_en_array_o     <= 1;
                            r_target_count_o <= 3;
                            if (w_over_array_i == 1) begin
                                movie_session <= w_array_input_i[19:5];
                                D10_end       <= 1;
                            end
                        end
                        else begin
                            r_en_array_o <= 0;
                        end
                    end
                    
                    D11:
                    begin
                        D1_end   <= 0;
                        D2_end   <= 0;
                        D3_end   <= 0;
                        D5_end   <= 0;
                        D6_end   <= 0;
                        D7_end   <= 0;
                        D8_end   <= 0;
                        D9_end   <= 0;
                        D10_end  <= 0;
                        r_show_o <= {blank,blank,o,u,t,5'd29};
                        if (D11_end == 0) begin
                            if (press == con) begin
                                r_ram_movie_operation_o <= delete_by_id;
                                r_ram_movie_id_o        <= {movie_id[7:5],movie_id[2:0]};
                            end
                            if (w_ram_movie_over_i == 1) begin
                                D11_end <= 1;
                            end
                        end
                        else begin
                            r_ram_movie_operation_o <= idle;
                        end
                    end
                endcase
            end
        end
    end
    
    
endmodule
