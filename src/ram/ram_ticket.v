module ram_ticket (input clk,
                   input rst_n,
                   input wire [9:0] w_cinema_time_i,
                   output reg can_be_vip,
                   input wire [2:0] operation,
                   input wire [31:0] ticket_index,
                   output reg over_o,
                   output reg wrong_o,
                   output reg working_o,
                   output wire [31:0] ticket_num_o,
                   input wire [5:0] id_i,
                   output reg [5:0] id_o,
                   input wire [64:0] data_i,
                   output reg [64:0] data_o,
                   output reg [7:0] led);
    
    parameter DEPTH                     = 64; // id range is 0*8^1+0*8^0 - 7*8^1+7*8^0, therefore the ram has the depth of 100, The id 00 we will not use. It means NULL
    parameter WIDTH                     = 65;
    parameter DATA_WIDTH                = 65;
    parameter ID_WIDTH                  = 6;
    parameter ADDR_WIDTH                = 6;
    parameter NULL                      = 0;
    parameter ID_BEGIN                  = 64;
    parameter ID_END                    = 59;
    parameter [58:0] other_data_initial = 59'b0;
    
    // ----------
    
    // ram: [ticket_id]  [ticket_movie]  [ticket_session]  [ticket_buy_time]   [ticket_price]  [ticket_state]     [ticket_seat]  [movie_id]   [use_vip]
    // .    (6-bit)      (5-bit)         (15-bit)          (10-bit)            (10-bit)        (2-bit)            (10-bit)       (6-bit)      (1-bit)
    // .    [2]          [1]             [3]               [2]                 [2]             [10:refund         [2]            [2]          [1:use
    // .                                                                                        01:is_used                                    0:not use]
    // .                                                                                        00:not_used]
    // bit: 64-59        58-54           53-39             38-29               28-19            18-17              16-7           6-1          0
    
    // ----------
    
    reg [WIDTH-1:0] ram [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0]    addr; // 6-bit binary
    reg                     wrong_flag;
    
    // ----------
    
    // these two stack is used to storage the address that no_data ram and have_data ram.
    // When we new an item, we will pop one address from stack_n(stack_data_no), and push this address into the stack_y(stack_data_yes)
    // When we delete an item, we will do it reverse
    
    reg [ADDR_WIDTH-1:0] stack_n [DEPTH-1:0];
    reg [5:0] stack_n_top;
    reg [ADDR_WIDTH-1:0] stack_y [DEPTH-1:0];
    reg [5:0] stack_y_top;
    reg [ADDR_WIDTH-1:0] index;
    
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
    
    assign ticket_num_o = stack_y_top - 1;
    
    // ----------
    
    reg [ADDR_WIDTH-1:0] i;
    
    reg[31:0]cnt;
    parameter period_fast = 500_000_00; // 0.5s
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end
        else begin
            if (cnt == period_fast - 1) begin
                cnt <= 0;
            end
            else
                cnt <= cnt+1;
        end
    end
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
                        if (ticket_index < ticket_num_o + 1 && ticket_index > 0) begin
                            addr       <= stack_y[ticket_index];
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
                    default:next_state <= present_state;
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
    
    integer i1;
    reg check_begin;
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o      <= 'bz;
            id_o        <= 6'bz;
            wrong_o     <= 0;
            over_o      <= 0;
            working_o   <= 0;
            can_be_vip  <= 0;
            index       <= 1;
            i1          <= 1;
            check_begin <= 0;
            
            stack_n_top <= 6'd63;
            stack_y_top <= 6'd1;
            for (i = 6'd63; i > 6'd0; i = i - 6'd1) begin
                stack_n[i] <= (6'd63 - i) + 6'd1; // 64 - i
                stack_y[i] <= NULL;
                ram[i]     <= {i, other_data_initial};
            end
            ram[0]     <= 'b0;
            stack_n[0] <= NULL;
            stack_y[0] <= NULL;
        end
        else begin
            case (present_state)
                new:
                begin
                    ram[addr] <= {ram[addr][ID_BEGIN:ID_END],data_i[58:0]};
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
                    ram[addr] <= {ram[addr][ID_BEGIN:ID_END],data_i[58:0]};
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
                        working_o <= 0;
                    end
                    else begin
                        over_o    <= 0;
                        working_o <= 0;
                    end
                    
                    if (cnt == period_fast - 1) begin
                        check_begin <= 1;
                    end
                    if (check_begin == 1) begin
                        i1 <= i1 + 1;
                        if (i1 < stack_y_top + 32'd1) begin
                            if (w_cinema_time_i + 10'b1 == ram[stack_y[i1[5:0]]][53:44]) begin
                                if (ram[stack_y[i1[5:0]]][18:17] == 2'b00) begin
                                    can_be_vip                   <= 1;
                                    ram[stack_y[i1[5:0]]][18:17] <= 2'b01;
                                end
                            end
                        end
                        else begin
                            check_begin <= 0;
                            i1          <= 1;
                        end
                    end
                end
                default:;
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
    
    
endmodule // ram_ticket
