// tip 1: the toppest state is the state idle(2'b00) in the cinema_top.v
// tip 2: In all module in this project, wire *_o in module A means module will use *_o to output data into other module, so is *_i. Therefore, you will see, .a_in(b_out). Or, .a_in(w_top), .b_out(w_top).
// trick 1: when we go down the bottom/son states(这里指所有子模块中的任何状态) and we want to go back to the toppest initial state(最顶层模块), We can just press the return initial state button.
// trick 2: when we are in the state that is the top state in some module (e.g. A0 in client_buy_ticket.v) and we want to return_last_state, which means we want to go to the cient_state_idle in client.v, we can use return_father_rst and return initial to implemnt.

`include "iostream/input_array.v"
`include "iostream/input_button_debounce.v"
`include "iostream/output_show.v"
`include "ram/ram_movie.v"
`include "ram/ram_ticket.v"
`include "ram/ram_vip.v"
`include "client/client.v"
`include "manager/manager.v"
`include "cinema_time.v"

module cinema_top (input clk,
                   input rst_n,                       // reset button is used to reset the whole program and memory.
                   input button_confirm,              // S2: mid button: you need press the confirm button, after you finish your input.
                   input button_return_initial_state, // S4: top button: it's used to return the initial state.
                   input button_return_last_state,    // S3: down button: it's used to return the last step.
                   input button_delete_or_last,       // S1: left button: used to delete the last input in the input pattern OR see the last item in the check pattern.
                   input button_next,                 // S0: right button: used to see next item in the check pattern.
                   input [7:0] switch,                // using 8 switches to input any value.
                   input [7:0] switch_small,
                   output [7:0] seg_en,
                   output [7:0] seg_out_0,
                   output [7:0] seg_out_1,
                   output wire [7:0] led,
                   output wire [7:0] led_small);
    
    assign led = switch;
    
    // parameter for 3-bit reg vector "press"
    
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
    
    
    // parameter for manager keyword
    parameter manager_key_word = {5'd1,5'd1,5'd1,5'd1};
    
    // ----------
    
    assign led_small[0] = switch_small[0];
    
    // ----------
    // debounce for the signal from the buttons, and get the 3-bit 'press'
    wire [2:0] press;
    
    input_button_debounce u_input_button_debounce
    (
    .clk(clk),
    .rst_n(rst_n),
    .button({
    button_return_initial_state,
    button_delete_or_last,
    button_confirm,
    button_return_last_state,
    button_next
    }),
    .press(press)
    );
    
    // ----------
    
    // when any module need Man input "xx id" or "xx password", array_input module will be activated. Then this module will get an array. (We allow delete in this module
    reg en_array_i;
    wire en_array_wire;
    reg [3:0] target_count_i;
    wire array_over_o;
    wire [19:0] array_input_o;
    
    input_array u_input_array
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_array_i),
    .switch(switch),
    .press(press),
    .target_count(target_count_i),
    .over(array_over_o),
    .array_input(array_input_o)
    );
    
    // ----------
    
    reg [39:0] show_i;
    output_show u_output_show
    (
    .clk(clk),
    .rst_n(rst_n),
    .period_show(show_i),
    .bit_sel(seg_en),
    .Y_0(seg_out_0),
    .Y_1(seg_out_1)
    );
    
    // ----------
    
    wire [9:0] w_time_o;
    
    cinema_time u_cinema_time
    (
    .clk(clk),
    .rst_n(rst_n),
    .switch_time_fast(switch_small[0]),
    .r_time_o(w_time_o)
    );
    
    // ----------
    
    // module movie, ticket, vip RAM
    
    wire [2:0]  w_ram_movie_operation;
    wire [31:0] w_ram_movie_index;
    wire        w_ram_movie_over;
    wire        w_ram_movie_wrong;
    wire        w_ram_movie_working;
    wire [31:0] w_ram_movie_num;
    wire [5:0]  w_ram_movie_id_i;
    wire [5:0]  w_ram_movie_id_o;
    wire [45:0] w_ram_movie_data_i;
    wire [45:0] w_ram_movie_data_o;
    
    ram_movie u_ram_movie
    (
    .clk(clk),
    .rst_n(rst_n),
    .operation(w_ram_movie_operation), // 3   bit
    .movie_index(w_ram_movie_index),   // 32  bit
    .over_o(w_ram_movie_over),         // 1   bit
    .wrong_o(w_ram_movie_wrong),       // 1   bit
    .working_o(w_ram_movie_working),   // 1   bit
    .movie_num_o(w_ram_movie_num),     // 32  bit
    .id_i(w_ram_movie_id_i),           // 6   bit
    .id_o(w_ram_movie_id_o),           // 6   bit
    .data_i(w_ram_movie_data_i),       // 46  bit
    .data_o(w_ram_movie_data_o)        // 46  bit
    );
    
    wire [2:0]  w_ram_ticket_operation;
    wire [31:0] w_ram_ticket_index;
    wire        w_ram_ticket_over;
    wire        w_ram_ticket_wrong;
    wire        w_ram_ticket_working;
    wire [31:0] w_ram_ticket_num;
    wire [5:0]  w_ram_ticket_id_i;
    wire [5:0]  w_ram_ticket_id_o;
    wire [64:0] w_ram_ticket_data_i;
    wire [64:0] w_ram_ticket_data_o;
    
    wire can_be_vip;
    
    ram_ticket u_ram_ticket
    (
    .clk(clk),
    .rst_n(rst_n),
    .w_cinema_time_i(w_time_o),
    .can_be_vip(can_be_vip),
    .operation(w_ram_ticket_operation), // 3   bit
    .ticket_index(w_ram_ticket_index),  // 32  bit
    .over_o(w_ram_ticket_over),         // 1   bit
    .wrong_o(w_ram_ticket_wrong),       // 1   bit
    .working_o(w_ram_ticket_working),   // 1   bi
    .ticket_num_o(w_ram_ticket_num),    // 32  bit
    .id_i(w_ram_ticket_id_i),           // 6   bit
    .id_o(w_ram_ticket_id_o),           // 6   bit
    .data_i(w_ram_ticket_data_i),       // 65  bit
    .data_o(w_ram_ticket_data_o)        // 65  bit
    );
    
    // ram vip
    wire [1:0] wr_ram_vip;
    wire [1:0] w_vip_i;
    wire [4:0] w_vip_movie_number_i;
    wire [31:0] w_vip_cost_i;
    wire [31:0] w_vip_save_i;
    wire [19:0] w_vip_password_i;
    wire [2:0] w_vip_day_i;
    wire [4:0] w_vip_off_i;
    
    wire [1:0] w_vip_o;
    wire [4:0] w_vip_movie_number_o;
    wire [31:0] w_vip_cost_o;
    wire [31:0] w_vip_save_o;
    wire [19:0] w_vip_password_o;
    wire [2:0] w_vip_day_o;
    wire [4:0] w_vip_off_o;
    
    ram_vip u_ram_vip
    (
    .clk(clk),
    .rst_n(rst_n),
    .wr_ram_vip(wr_ram_vip),
    
    .w_vip_i(w_vip_i),
    .w_vip_movie_number_i(w_vip_movie_number_i),
    .w_vip_cost_i(w_vip_cost_i),
    .w_vip_save_i(w_vip_save_i),
    .w_vip_password_i(w_vip_password_i),
    .w_vip_day_i(w_vip_day_i),
    .w_vip_off_i(w_vip_off_i),
    
    .r_vip_o(w_vip_o),
    .r_vip_movie_number_o(w_vip_movie_number_o),
    .r_vip_cost_o(w_vip_cost_o),
    .r_vip_save_o(w_vip_save_o),
    .r_vip_password_o(w_vip_password_o),
    .r_vip_day_o(w_vip_day_o),
    .r_vip_off_o(w_vip_off_o),
    
    .can_be_vip(can_be_vip)
    );
    
    // ----------
    
    reg return_initial;
    wire return_initial_client;
    wire return_initial_manager;
    
    // module client and manager
    
    wire [3:0] w_target_count_client;
    wire [29:0] w_client_show_o;
    reg en_client;
    
    client u_client
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_client),
    .en_father_rst(return_initial_client),
    .w_cinema_time_i(w_time_o),
    
    .press(press),
    .switch(switch),
    .w_target_count_o(w_target_count_client),
    .w_en_array_o(en_array_wire),
    .w_over_array_i(array_over_o),
    .w_array_input_i(array_input_o),
    .r_show_o(w_client_show_o),
    
    .w_ram_movie_operation_o(w_ram_movie_operation),
    .w_ram_movie_index_o(w_ram_movie_index),
    .w_ram_movie_over_i(w_ram_movie_over),
    .w_ram_movie_wrong_i(w_ram_movie_wrong),
    .w_ram_movie_working_i(w_ram_movie_working),
    .w_ram_movie_num_i(w_ram_movie_num),
    .w_ram_movie_id_i(w_ram_movie_id_o),
    .w_ram_movie_id_o(w_ram_movie_id_i),
    .w_ram_movie_data_i(w_ram_movie_data_o),
    .w_ram_movie_data_o(w_ram_movie_data_i),
    
    .w_ram_ticket_operation_o(w_ram_ticket_operation),
    .w_ram_ticket_index_o(w_ram_ticket_index),
    .w_ram_ticket_over_i(w_ram_ticket_over),
    .w_ram_ticket_wrong_i(w_ram_ticket_wrong),
    .w_ram_ticket_working_i(w_ram_ticket_working),
    .w_ram_ticket_num_i(w_ram_ticket_num),
    .w_ram_ticket_id_i(w_ram_ticket_id_o),
    .w_ram_ticket_id_o(w_ram_ticket_id_i),
    .w_ram_ticket_data_i(w_ram_ticket_data_o),
    .w_ram_ticket_data_o(w_ram_ticket_data_i),
    
    .w_wr_ram_vip_o(wr_ram_vip),
    .w_vip_o(w_vip_i),
    .w_vip_movie_number_o(w_vip_movie_number_i),
    .w_vip_cost_o(w_vip_cost_i),
    .w_vip_save_o(w_vip_save_i),
    .w_vip_password_o(w_vip_password_i),
    .w_vip_day_o(w_vip_day_i),
    .w_vip_off_o(w_vip_off_i),
    .w_vip_i(w_vip_o),
    .w_vip_movie_number_i(w_vip_movie_number_o),
    .w_vip_cost_i(w_vip_cost_o),
    .w_vip_save_i(w_vip_save_o),
    .w_vip_password_i(w_vip_password_o),
    .w_vip_day_i(w_vip_day_o),
    .w_vip_off_i(w_vip_off_o),
    
    .led_small(led_small[7:3])
    );
    
    wire [3:0] w_target_count_manager;
    wire [29:0] w_manager_show_o;
    reg en_manager;
    
    manager u_manager
    (
    .clk(clk),
    .rst_n(rst_n),
    .en(en_manager),
    .en_father_rst(return_initial_manager),
    
    .press(press),
    .switch(switch),
    .w_target_count_o(w_target_count_manager),
    .w_en_array_o(en_array_wire),
    .w_over_array_i(array_over_o),
    .w_array_input_i(array_input_o),
    .r_show_o(w_manager_show_o),
    
    .w_ram_movie_operation_o(w_ram_movie_operation),
    .w_ram_movie_index_o(w_ram_movie_index),
    .w_ram_movie_over_i(w_ram_movie_over),
    .w_ram_movie_wrong_i(w_ram_movie_wrong),
    .w_ram_movie_working_i(w_ram_movie_working),
    .w_ram_movie_num_i(w_ram_movie_num),
    .w_ram_movie_id_i(w_ram_movie_id_o),
    .w_ram_movie_id_o(w_ram_movie_id_i),
    .w_ram_movie_data_i(w_ram_movie_data_o),
    .w_ram_movie_data_o(w_ram_movie_data_i),
    
    .w_ram_ticket_operation_o(w_ram_ticket_operation),
    .w_ram_ticket_index_o(w_ram_ticket_index),
    .w_ram_ticket_over_i(w_ram_ticket_over),
    .w_ram_ticket_wrong_i(w_ram_ticket_wrong),
    .w_ram_ticket_working_i(w_ram_ticket_working),
    .w_ram_ticket_num_i(w_ram_ticket_num),
    .w_ram_ticket_id_i(w_ram_ticket_id_o),
    .w_ram_ticket_id_o(w_ram_ticket_id_i),
    .w_ram_ticket_data_i(w_ram_ticket_data_o),
    .w_ram_ticket_data_o(w_ram_ticket_data_i),
    
    .w_wr_ram_vip_o(wr_ram_vip),
    .w_vip_off_o(w_vip_off_i),
    .w_vip_off_i(w_vip_off_o),
    
    .led_small(led_small[5:3])
    );
    
    // ----------
    
    // the toppest state machine
    // .                     idle_top(000)
    // . state_client(001)                     state_manager_input_password(010) state_manager_password_wrong(011)
    // .                  state_manager(100)
    parameter idle_top                     = 3'b000;
    parameter state_client                 = 3'b001;
    parameter state_manager_input_password = 3'b010;
    parameter state_manager_password_wrong = 3'b011;
    parameter state_manager                = 3'b100;
    
    reg [2:0] present_state;
    reg [2:0] next_state;
    reg [1:0] led_small_first_level;
    assign led_small[2:1] = led_small_first_level;
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            present_state <= idle_top;
        end
        else begin
            if (return_initial) begin
                present_state <= idle_top;
            end
            else begin
                present_state <= next_state;
            end
        end
    end
    
    // get next state
    reg input_password_end;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state <= idle_top;
        end
        else begin
            if (return_initial) begin
                next_state <= idle_top;
            end
            else begin
                case (present_state)
                    idle_top:
                    case(press)
                        con:
                        case (switch)
                            8'b0000_0001: next_state <= state_client;
                            8'b0000_0010: next_state <= state_manager_input_password;
                        endcase
                    endcase
                    
                    state_manager_input_password:
                    begin
                        if (input_password_end == 1) begin
                            if (array_input_o == manager_key_word) begin
                                next_state <= state_manager;
                            end
                            else begin
                                next_state <= state_manager_password_wrong;
                            end
                        end
                        else begin
                            case(press)
                                rls: next_state <= idle_top;
                                ris: next_state <= idle_top;
                            endcase
                        end
                    end
                    
                    state_manager_password_wrong:
                    case(press)
                        con: next_state <= state_manager_input_password;
                        rls: next_state <= state_manager_input_password;
                        ris: next_state <= idle_top;
                    endcase
                    
                    default:
                    if (press == ris) begin
                        next_state <= idle_top;
                    end
                endcase
            end
        end
    end
    
    // get output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_client             <= 0;
            en_manager            <= 0;
            input_password_end    <= 0;
            show_i[39:0]          <= 'bz;
            en_array_i            <= 'bz;
            target_count_i        <= 'bz;
            led_small_first_level <= 'bz;
            return_initial        <= 0;
        end
        else begin
            show_i[39:30] <= w_time_o;
            case (present_state)
                idle_top:
                begin
                    input_password_end    <= 0;
                    en_client             <= 0;
                    en_manager            <= 0;
                    show_i[29:0]          <= {blank,blank,blank,t,o,p};
                    en_array_i            <= 0;
                    target_count_i        <= 0;
                    led_small_first_level <= 2'b01;
                    return_initial        <= 0;
                end
                
                state_client:
                begin
                    en_client  <= 1;
                    en_manager <= 0;
                    if (en_array_wire == 1) begin
                        show_i[29:20] <= w_client_show_o[29:20];
                        show_i[19:0]  <= array_input_o;
                    end
                    else begin
                        show_i[29:0] <= w_client_show_o;
                    end
                    en_array_i            <= en_array_wire;
                    target_count_i        <= w_target_count_client;
                    led_small_first_level <= 2'b10;
                    return_initial        <= return_initial_client;
                end
                
                state_manager_input_password:
                begin
                    en_client  <= 0;
                    en_manager <= 0;
                    if (input_password_end == 0) begin
                        en_array_i     <= 1;
                        target_count_i <= 4;
                        if (array_over_o == 1) begin
                            input_password_end <= 1;
                        end
                    end
                    else begin
                        en_array_i <= 0;
                    end
                    show_i[29:0]   <= {p,blank,array_input_o};
                    return_initial <= 0;
                end
                
                state_manager_password_wrong:
                begin
                    input_password_end <= 0;
                    en_client          <= 0;
                    en_manager         <= 0;
                    show_i[29:0]       <= {blank,e,r,r,o,r};
                    return_initial     <= 0;
                end
                
                state_manager:
                begin
                    input_password_end <= 0;
                    en_client          <= 0;
                    en_manager         <= 1;
                    if (en_array_wire == 1) begin
                        show_i[29:20] <= w_manager_show_o[29:20];
                        show_i[19:0]  <= array_input_o;
                    end
                    else begin
                        show_i[29:0] <= w_manager_show_o;
                    end
                    en_array_i            <= en_array_wire;
                    target_count_i        <= w_target_count_manager;
                    led_small_first_level <= 2'b11;
                    return_initial        <= return_initial_manager;
                end
            endcase
        end
    end
    
endmodule
    
