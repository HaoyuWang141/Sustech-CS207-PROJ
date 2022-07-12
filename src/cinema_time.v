module cinema_time (input clk,
                    input rst_n,
                    input switch_time_fast,
                    output wire [9:0] r_time_o);
    
    reg[4:0] week; // decide which day such as the Monday,Tuesday.
    reg[4:0] hour; // decide which day such as the 0-9 represents the time.
    reg[31:0]cnt;
    reg clkout;
    assign r_time_o       = {week,hour};
    parameter period      = 1000_000_000; // 10s
    parameter period_fast = 500_000_00;   // 0.5s
    always@(posedge clk or negedge rst_n) // frequency division;
    begin
        if (!rst_n)
        begin
            cnt <= 0;
            clkout = 0;
        end
        else begin
            if (switch_time_fast == 1) begin
                if (cnt > (period_fast>>1)-1) begin
                    cnt <= 0;
                end
                else begin
                    if (cnt == (period_fast>>1)-1)
                    begin
                        clkout <= ~clkout;
                        cnt    <= 0;
                    end
                    else
                        cnt <= cnt+1;
                end
            end
            else begin
                if (cnt == (period>>1)-1)
                begin
                    clkout <= ~clkout;
                    cnt    <= 0;
                end
                else
                    cnt <= cnt+1;
            end
        end
    end
    
    always@(posedge clkout or negedge rst_n) // change scan_cnt based on clkout;
    begin
        if (!rst_n)
        begin
            week <= 5'b0_0001;
            hour <= 5'b0_0000;
        end
        else begin
            if (hour == 5'b0_1001)
            begin
                if (week == 5'b0_0111)
                begin
                    week <= 5'b00001;
                    hour <= 5'b0_0000;
                end
                else
                begin
                    week <= week+1;
                    hour <= 5'b0_0000;
                end
            end
            else
                hour <= hour+1;
        end
    end
    
    
endmodule // movie_start
