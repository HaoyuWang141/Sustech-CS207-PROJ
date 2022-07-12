module buffer (input clk,
               input rst_n,
               input en,
               input index,
               input [9:0] id,
               input [2:0] operation,
               output reg wrong,
               output reg [5:0] movie_num, // output movie
               output reg [9:0] movie_id,
               output reg [4:0] movie_name,
               output reg [9:0] movie_price,
               output reg [14:0] movie_session,
               output reg [4:0] movie_rest_ticket,
               output reg [3:0] movie_seat,
               output reg [5:0] ticket_num, // output ticket
               output reg [9:0] ticket_id,
               output reg [4:0] ticket_movie,
               output reg [14:0] ticket_session,
               output reg [9:0] ticket_buy_time,
               output reg [9:0] ticket_price,
               output reg [1:0] ticket_state,
               output reg [9:0] ticket_seat,
               output reg [9:0] ticket_movie_id,
               output reg use_vip,
               output reg [2:0] w_ram_movie_operation_o, // read movie from ram
               input wire w_ram_movie_over_i,
               input wire w_ram_movie_wrong_i,
               input wire [5:0] w_ram_movie_n_i,
               inout wire [5:0] w_ram_movie_id_io,
               inout wire [45:0] w_ram_movie_data_io,
               output reg [2:0] w_ram_ticket_operation_o, // read ticket from ram
               input wire w_ram_ticket_over_i,
               input wire w_ram_ticket_wrong_i,
               input wire [5:0] w_ram_ticket_n_i,
               inout wire [5:0] w_ram_ticket_id_io,
               inout wire [64:0] w_ram_ticket_data_io);
    
    // operation: 111 idle, 00 movie by index, 01 movie by id
    parameter movie_by_index  = 3'b000;
    parameter movie_by_id     = 3'b001;
    parameter ticket_by_index = 3'b010;
    parameter ticket_by_id    = 3'b011;
    parameter idle_buffer     = 3'b111;
    
    parameter new          = 3'b000;
    parameter read_by_id   = 3'b001;
    parameter change_by_id = 3'b010;
    parameter delete_by_id = 3'b011;
    parameter read_all     = 3'b100;
    parameter clear_all    = 3'b101;
    parameter idle         = 3'b111;
    
    integer cnt;
    parameter PERIOD = 1000_000;
    always @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
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
    
    integer index_movie;
    reg [9:0] buffer_movie_id [64:0];
    reg [4:0] buffer_movie_name [64:0];
    reg [9:0] buffer_movie_price [64:0];
    reg [14:0] buffer_movie_session [64:0];
    reg [4:0] buffer_movie_rest_ticket [64:0];
    reg [3:0] buffer_movie_seat [64:0];
    
    integer index_ticket;
    reg [9:0] buffer_ticket_id [64:0];
    reg [4:0] buffer_ticket_movie [64:0];
    reg [14:0] buffer_ticket_session [64:0];
    reg [9:0] buffer_ticket_buy_time [64:0];
    reg [9:0] buffer_ticket_price [64:0];
    reg [1:0] buffer_ticket_state [64:0];
    reg [9:0] buffer_ticket_seat [64:0];
    reg [9:0] buffer_ticket_movie_id [64:0];
    reg buffer_use_vip [64:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            w_ram_movie_operation_o  <= 3'bz;
            w_ram_ticket_operation_o <= 3'bz;
            movie_num                <= 0;
            ticket_num               <= 0;
        end
        else begin
            if (!en) begin
                w_ram_movie_operation_o  <= 3'bz;
                w_ram_ticket_operation_o <= 3'bz;
                movie_num                <= 0;
                ticket_num               <= 0;
            end
            else begin
                if (cnt == PERIOD - 1) begin
                    w_ram_movie_operation_o  <= read_all;
                    w_ram_ticket_operation_o <= read_all;
                    movie_num                <= 0;
                    ticket_num               <= 0;
                end
                
                if (w_ram_movie_operation_o == read_all) begin
                    buffer_movie_id[w_ram_movie_n_i]          <= {2'b00,w_ram_movie_data_io[45:43],2'b00,w_ram_movie_data_io[42:40]};
                    buffer_movie_name[w_ram_movie_n_i]        <= w_ram_movie_data_io[39:35];
                    buffer_movie_price[w_ram_movie_n_i]       <= w_ram_movie_data_io[34:25];
                    buffer_movie_session[w_ram_movie_n_i]     <= w_ram_movie_data_io[24:10];
                    buffer_movie_rest_ticket[w_ram_movie_n_i] <= w_ram_movie_data_io[9:5];
                    buffer_movie_seat[w_ram_movie_n_i]        <= w_ram_movie_data_io[4:1];
                    
                    if (w_ram_movie_n_i + 1 > movie_num) begin
                        movie_num <= w_ram_movie_n_i + 1;
                    end
                end
                
                if (w_ram_ticket_operation_o == read_all) begin
                    buffer_ticket_id[w_ram_ticket_n_i]       <= {2'b00,w_ram_ticket_data_io[64:62],2'b00,w_ram_movie_data_io[61:59]};
                    buffer_ticket_movie[w_ram_ticket_n_i]    <= w_ram_ticket_data_io[58:54];
                    buffer_ticket_session[w_ram_ticket_n_i]  <= w_ram_ticket_data_io[53:39];
                    buffer_ticket_buy_time[w_ram_ticket_n_i] <= w_ram_ticket_data_io[38:29];
                    buffer_ticket_price[w_ram_ticket_n_i]    <= w_ram_ticket_data_io[28:19];
                    buffer_ticket_state[w_ram_ticket_n_i]    <= w_ram_ticket_data_io[18:17];
                    buffer_ticket_seat[w_ram_ticket_n_i]     <= w_ram_ticket_data_io[16:7];
                    buffer_ticket_movie_id[w_ram_ticket_n_i] <= w_ram_ticket_data_io[6:1];
                    buffer_use_vip[w_ram_ticket_n_i]         <= w_ram_ticket_data_io[0];
                    
                    if (w_ram_ticket_n_i + 1 > ticket_num) begin
                        ticket_num <= w_ram_ticket_n_i + 1;
                    end
                end
                
                if (w_ram_movie_over_i == 1) begin
                    w_ram_movie_operation_o <= idle;
                end
                
                if (w_ram_ticket_over_i == 1) begin
                    w_ram_ticket_operation_o <= idle;
                end
            end
        end
    end
    
    always @(operation) begin
        case (operation)
            movie_by_index:
            begin
                if (index < movie_num) begin
                    wrong             = 0;
                    movie_id          = buffer_movie_id[index];
                    movie_name        = buffer_movie_name[index];
                    movie_price       = buffer_movie_price[index];
                    movie_session     = buffer_movie_session[index];
                    movie_rest_ticket = buffer_movie_rest_ticket[index];
                    movie_seat        = buffer_movie_seat[index];
                end
                else begin
                    wrong             = 1;
                    movie_id          = 100'bz;
                    movie_name        = 100'bz;
                    movie_price       = 100'bz;
                    movie_session     = 100'bz;
                    movie_rest_ticket = 100'bz;
                    movie_seat        = 100'bz;
                end
            end
            
            movie_by_id:
            begin
                index_movie = index_of_movie_id(id);
                if (index_movie == 10'b0) begin
                    wrong = 1;
                end
                else begin
                    
                end
            end
            
            ticket_by_index:
            begin
                if (index < movie_num) begin
                    wrong           = 0;
                    ticket_id       = buffer_ticket_id [index];
                    ticket_movie    = buffer_ticket_movie [index];
                    ticket_session  = buffer_ticket_session [index];
                    ticket_buy_time = buffer_ticket_buy_time [index];
                    ticket_price    = buffer_ticket_price [index];
                    ticket_state    = buffer_ticket_state [index];
                    ticket_seat     = buffer_ticket_seat [index];
                    ticket_movie_id = buffer_ticket_movie_id [index];
                    use_vip         = buffer_use_vip [index];
                end
                else begin
                    wrong           = 1;
                    ticket_id       = 100'bz;
                    ticket_movie    = 100'bz;
                    ticket_session  = 100'bz;
                    ticket_buy_time = 100'bz;
                    ticket_price    = 100'bz;
                    ticket_state    = 100'bz;
                    ticket_seat     = 100'bz;
                    ticket_movie_id = 100'bz;
                    use_vip         = 100'bz;
                end
            end
            
            ticket_by_id:;
            
            idle:
            begin
                movie_id          = 100'bz;
                movie_name        = 100'bz;
                movie_price       = 100'bz;
                movie_session     = 100'bz;
                movie_rest_ticket = 100'bz;
                movie_seat        = 100'bz;
                ticket_id         = 100'bz;
                ticket_movie      = 100'bz;
                ticket_session    = 100'bz;
                ticket_buy_time   = 100'bz;
                ticket_price      = 100'bz;
                ticket_state      = 100'bz;
                ticket_seat       = 100'bz;
                ticket_movie_id   = 100'bz;
                use_vip           = 100'bz;
            end
        endcase
    end
    
    function [9:0] index_of_movie_id;
        input id;
        integer i1;
        begin
            index_of_movie_id = 64;
            for (i1 = 1; i1 < movie_num + 1; i1 = i1 + 1) begin
                if (id == buffer_movie_id[i1]) begin
                    index_of_movie_id = i1;
                end
            end
        end
    endfunction
    
    function [9:0] index_of_tiket_id;
        input id;
        integer i2;
        begin
            index_of_tiket_id = 64;
            for (i2 = 1; i2 < movie_num + 1; i2 = i2 + 1) begin
                if (id == buffer_movie_id[i2]) begin
                    index_of_tiket_id = i2;
                end
            end
        end
    endfunction
endmodule // buffer
