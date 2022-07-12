module ram_movie (input clk,
                  input rst_n,
                  input wire [2:0] operation,
                  input wire [31:0] movie_index,
                  output reg over_o,
                  output reg wrong_o,
                  output reg working_o,
                  output wire [31:0] movie_num_o,
                  input wire [5:0] id_i,
                  output reg [5:0] id_o,
                  input wire [45:0] data_i,
                  output reg [45:0] data_o,
                  output reg [7:0] led);
    
    parameter DEPTH                     = 64; // id range is 0*8^1+0*8^0 - 7*8^1+7*8^0, therefore the ram has the depth of 100, The id 00 we will not use. It means NULL
    parameter WIDTH                     = 46;
    parameter DATA_WIDTH                = 46;
    parameter ID_WIDTH                  = 6;
    parameter ADDR_WIDTH                = 6;
    parameter NULL                      = 0;
    parameter ID_BEGIN                  = 45;
    parameter ID_END                    = 40;
    parameter [39:0] other_data_initial = 40'b0;
    
    // ----------
    
    // ram: [movie_id]  [movie_name]  [movie_price]  [movie_session]  [movie_rest_ticket]  [movie_seat]  [have_data]
    // .    (6-bit)     (5-bit)       (10-bit)       (15-bit)         (5-bit)              (4-bit)       (1-bit)
    // .    [2]         [1]           [2]            [3]              [1]                  [4 binary]    [1:n_empty / 0:empty]
    // bit: 45-40       39-35         34-25          24-10            9-5                  4-1           0
    // .                                                                                                 !don't use in project!
    
    // ----------
    
    reg [WIDTH-1:0] ram [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] addr; // 6-bit
    reg wrong_flag;            // assign in combination logic "get next state"
    
    // ----------
    
    // these two stack is used to storage the address that no_data ram and have_data ram.
    // When we new an item, we will pop one address from stack_n(stack_data_no), and push this address into the stack_y(stack_data_yes)
    // When we delete an item, we will do it reverse
    
    reg     [ADDR_WIDTH-1:0]    stack_n [DEPTH-1:0];
    reg     [5:0]               stack_n_top;
    reg     [ADDR_WIDTH-1:0]    stack_y [DEPTH-1:0];
    reg     [5:0]               stack_y_top;
    reg     [ADDR_WIDTH-1:0]    index;
    
    // ----------
    
    // state
    
    parameter idle          = 3'b000; // do nothing - all inout port shoule be high impedance for output
    parameter new           = 3'b001; // add a new item into RAM and return an id (data_io as input, id_io as output)
    parameter read_by_id    = 3'b010; // read and output the data of one item by inputing an id (data_io as output, id_io as input)
    parameter change_by_id  = 3'b011; // change the data of one item by inputing an id (data_io as input, id_io as input)
    parameter delete_by_id  = 3'b100; // delete the data of one item by inputing an id (data_io is not used, id_io as input)
    parameter read_by_index = 3'b101; // (data_io as output, id_io as output)
    parameter clear_all     = 3'b111; // clear all data
    
    reg [2:0] present_state;
    reg [2:0] next_state;
    
    // ----------
    
    assign movie_num_o = stack_y_top - 1;
    
    // ----------
    
    reg [ADDR_WIDTH-1:0] i;
    reg [ADDR_WIDTH-1:0] i2;
    reg [ADDR_WIDTH-1:0] i3;
    
    // state transition
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            present_state <= idle;
        end
        else begin
            present_state <= next_state;
        end
    end
    
    reg [5:0] index_delete_by_id;
    // get next state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state         <= idle;
            wrong_flag         <= 0;
            addr               <= NULL;
            index_delete_by_id <= 0;
        end
        else begin
            if (present_state == idle) begin
                case(operation)
                    new:
                    begin
                        if (stack_n_top == 0) begin
                            addr       <= NULL;
                            next_state <= idle;
                            wrong_flag <= 1;
                        end
                        else begin
                            addr       <= stack_n[stack_n_top];
                            next_state <= new;
                            wrong_flag <= 0;
                        end
                    end
                    read_by_id:
                    begin
                        if (id_have_data(id_i) == 1) begin
                            addr       <= id_i;
                            next_state <= read_by_id;
                            wrong_flag <= 0;
                        end
                        else begin
                            addr       <= NULL;
                            next_state <= idle;
                            wrong_flag <= 1;
                        end
                    end
                    change_by_id:
                    begin
                        if (id_have_data(id_i) == 1) begin
                            addr       <= id_i;
                            next_state <= change_by_id;
                            wrong_flag <= 0;
                        end
                        else begin
                            addr       <= NULL;
                            next_state <= idle;
                            wrong_flag <= 1;
                        end
                    end
                    delete_by_id:
                    begin
                        if (id_have_data(id_i) == 1) begin
                            addr               <= id_i;
                            index_delete_by_id <= id_position_in_stack_y(id_i);
                            next_state         <= delete_by_id;
                            wrong_flag         <= 0;
                        end
                        else begin
                            addr       <= NULL;
                            next_state <= idle;
                            wrong_flag <= 1;
                        end
                    end
                    read_by_index:
                    begin
                        if (movie_index < movie_num_o + 1 && movie_index > 0) begin
                            addr       <= stack_y[movie_index];
                            next_state <= read_by_index;
                            wrong_flag <= 0;
                        end
                        else begin
                            next_state <= idle;
                            wrong_flag <= 1;
                        end
                    end
                    clear_all:
                    begin
                        next_state <= clear_all;
                        wrong_flag <= 0;
                    end
                    idle:
                    begin
                        next_state         <= idle;
                        wrong_flag         <= 0;
                        addr               <= NULL;
                        index_delete_by_id <= 0;
                    end
                endcase
            end
            else begin
                if (operation == idle) begin
                    next_state         <= idle;
                    wrong_flag         <= 0;
                    addr               <= NULL;
                    index_delete_by_id <= 0;
                end
            end
        end
    end
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o    <= 'bz;
            id_o      <= 6'bz;
            wrong_o   <= 0;
            over_o    <= 0;
            working_o <= 0;
            
            for (i = 6'd63; i > 6'd4; i = i - 6'd1) begin
                ram[i] <= {i, other_data_initial};
            end
            ram[0] <= 'b0;
            ram[1] <= {6'd1,5'ha,5'd2,5'd0,5'd1,5'd3,5'd4,5'd4,4'b0000,1'b1};
            ram[2] <= {6'd2,5'ha,5'd3,5'd0,5'd2,5'd1,5'd2,5'd4,4'b0000,1'b1};
            ram[3] <= {6'd3,5'hb,5'd4,5'd0,5'd3,5'd5,5'd6,5'd4,4'b0000,1'b1};
            ram[4] <= {6'd4,5'hc,5'd5,5'd0,5'd4,5'd7,5'd8,5'd4,4'b0000,1'b1};
            
            stack_n_top <= 6'd59;
            for (i2 = 6'd1; i2 < 6'd60; i2 = i2 + 6'd1) begin
                stack_n[i2] <= (6'd63 - i2) + 6'd1; // 64 - i
            end
            stack_n[0]  <= NULL;
            stack_n[60] <= NULL;
            stack_n[61] <= NULL;
            stack_n[62] <= NULL;
            stack_n[63] <= NULL;
            
            stack_y_top <= 6'd5;
            for (i3 = 6'd63; i3 > 6'd4; i3 = i3 - 6'd1) begin
                stack_y[i] <= NULL;
            end
            stack_y[0] <= NULL;
            stack_y[1] <= 6'd1;
            stack_y[2] <= 6'd2;
            stack_y[3] <= 6'd3;
            stack_y[4] <= 6'd4;
        end
        else begin
            case (present_state)
                new:
                begin
                    ram[addr] <= {ram[addr][ID_BEGIN:ID_END],data_i[39:1],1'b1};
                    data_o    <= 'bz;
                    id_o      <= ram[addr][ID_BEGIN:ID_END];
                    wrong_o   <= 0;
                    working_o <= 1;
                    
                    if (over_o == 0) begin
                        stack_n[stack_n_top] <= NULL;
                        stack_n_top          <= stack_n_top - 1;
                        stack_y_top          <= stack_y_top + 1;
                        stack_y[stack_y_top] <= addr;
                        over_o               <= 1;
                    end
                    else begin
                        ;
                    end
                end
                
                read_by_id:
                begin
                    data_o    <= ram[addr];
                    id_o      <= 6'bz;
                    wrong_o   <= 0;
                    over_o    <= 1;
                    working_o <= 1;
                end
                
                change_by_id:
                begin
                    ram[addr] <= {ram[addr][ID_BEGIN:ID_END],data_i[39:1],1'b1};
                    data_o    <= 'bz;
                    id_o      <= 6'bz;
                    wrong_o   <= 0;
                    over_o    <= 1;
                    working_o <= 1;
                end
                
                delete_by_id:
                begin
                    ram[addr] <= {ram[addr][ID_BEGIN:ID_END],other_data_initial};
                    data_o    <= 'bz;
                    id_o      <= 6'bz;
                    wrong_o   <= 0;
                    working_o <= 1;
                    
                    if (over_o == 0) begin
                        stack_y[index_delete_by_id] <= stack_y[stack_y_top];
                        stack_y[stack_y_top]        <= NULL;
                        stack_y_top                 <= stack_y_top - 1;
                        stack_n_top                 <= stack_n_top + 1;
                        stack_n[stack_n_top]        <= addr;
                        over_o                      <= 1;
                    end
                    else begin
                        ;
                    end
                end
                
                read_by_index:
                begin
                    data_o    <= ram[addr];
                    id_o      <= ram[addr][ID_BEGIN:ID_END];
                    wrong_o   <= 0;
                    over_o    <= 1;
                    working_o <= 1;
                end
                
                clear_all:
                begin
                    if (index < 63) begin
                        index          <= index + 1;
                        stack_n[index] <= (6'd63 - index) + 6'd1; // 64 - index
                        stack_y[index] <= NULL;
                        ram[index]     <= {index, other_data_initial};
                        over_o         <= 0;
                        working_o      <= 1;
                    end
                    else begin
                        stack_n_top <= 63;
                        stack_y_top <= 1;
                        
                        ram[0]     <= 'b0;
                        stack_n[0] <= NULL;
                        stack_y[0] <= NULL;
                        
                        over_o <= 1;
                    end
                    
                    data_o  <= 'bz;
                    id_o    <= 6'bz;
                    wrong_o <= 0;
                end
                
                idle:
                begin
                    data_o  <= 'bz;
                    id_o    <= 6'bz;
                    index   <= 1;
                    wrong_o <= wrong_flag;
                    if (wrong_flag == 1) begin
                        over_o    <= 1;
                        working_o <= 1;
                    end
                    else begin
                        over_o    <= 0;
                        working_o <= 0;
                    end
                end
            endcase
        end
    end
    
    // if input id have data, return 1; if input id don't have data, return 0
    function id_have_data;
        input [5:0] id;
        integer j;
        begin
            id_have_data = 0;
            for (j = 1; j < stack_y_top + 1; j = j + 1) begin
                if (id == stack_y[j[5:0]]) begin
                    id_have_data = 1;
                end
            end
        end
    endfunction
    
    // return the address of input id, if input id is NOT have data, return 0
    function [5:0] id_position_in_stack_y;
        input [5:0] id;
        integer j;
        begin
            id_position_in_stack_y = 0;
            for (j = 1; j < stack_y_top + 1; j = j + 1) begin
                if (id == stack_y[j[5:0]]) begin
                    id_position_in_stack_y = j[5:0];
                end
            end
        end
    endfunction
    
endmodule // ram_movie
