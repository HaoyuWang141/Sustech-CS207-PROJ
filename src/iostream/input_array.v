module input_array (input clk,
                    input rst_n,
                    input en,
                    input wire [7:0] switch,
                    input wire [2:0] press,
                    input wire [3:0] target_count,
                    output reg over,
                    output wire [19:0] array_input);
    
    parameter nxt  = 3'b000; // check the next item
    parameter rls  = 3'b001; // return the toppest initial state
    parameter con  = 3'b010; // confirm
    parameter del  = 3'b011; // return last state
    parameter ris  = 3'b100; // delete or check the last item
    parameter none = 3'b111; // do nothing, no button is pressed
    
    reg [3:0] cnt;
    reg [4:0] buffer_i [3:0];
    
    assign array_input = {buffer_i[0],buffer_i[1],buffer_i[2],buffer_i[3]};
    
    // output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            over <= 0;
        end
        else begin
            if (!en) begin
                over <= 0;
            end
            else begin
                if (press == con && cnt == target_count) begin
                    over <= 1;
                end
                else begin
                    over <= 0;
                end
            end
        end
    end
    
    // input switch data when press the button
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt         <= 0;
            buffer_i[0] <= 5'd31;
            buffer_i[1] <= 5'd31;
            buffer_i[2] <= 5'd31;
            buffer_i[3] <= 5'd31;
        end
        else begin
            if (!en) begin
                cnt         <= 0;
                buffer_i[0] <= 5'd31;
                buffer_i[1] <= 5'd31;
                buffer_i[2] <= 5'd31;
                buffer_i[3] <= 5'd31;
            end
            else begin
                if (press == con && cnt < target_count) begin
                    case (switch)
                        8'b0000_0001:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd0;
                        end
                        8'b0000_0010:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd1;
                        end
                        8'b0000_0100:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd2;
                        end
                        8'b0000_1000:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd3;
                        end
                        8'b0001_0000:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd4;
                        end
                        8'b0010_0000:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd5;
                        end
                        8'b0100_0000:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd6;
                        end
                        8'b1000_0000:
                        begin
                            cnt           <= cnt + 1;
                            buffer_i[cnt] <= 5'd7;
                        end
                        default: buffer_i[cnt] <= 5'd31;
                    endcase
                end
                else begin
                    if (press == del && cnt > 0) begin
                        buffer_i[cnt-1] <= 5'd31;
                        cnt             <= cnt - 1;
                    end
                    else begin
                        ;
                    end
                end
            end
        end
    end
    
endmodule // switch_input
