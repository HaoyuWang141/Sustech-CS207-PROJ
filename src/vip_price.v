module vip_price (input [9:0] movie_price,
                  input [4:0] vip_off, // range for vip_off: 1-9，means vip_price = movie_price*((10-vip_off)/10)
                  output wire [31:0] ticket_price_integer,
                  output wire [31:0] save_money_integer,
                  output wire [9:0] ticket_price,
                  output wire [9:0] save_money);

wire [4:0] ticket_price_1;
wire [4:0] ticket_price_2;
wire [4:0] save_money_1;
wire [4:0] save_money_2;

assign ticket_price_integer = (movie_price[9:5] * 5'd10 + movie_price[4:0]) * (5'd10 - vip_off) / 5'd10;
assign save_money_integer   = (movie_price[9:5] * 5'd10 + movie_price[4:0]) * vip_off / 5'd10;
assign ticket_price_1       = ticket_price_integer / 32'd10;
assign ticket_price_2       = ticket_price_integer % 32'd10;
assign save_money_1         = save_money_integer / 32'd10;
assign save_money_2         = save_money_integer % 32'd10;

assign ticket_price = {ticket_price_1,ticket_price_2};
assign save_money   = {save_money_1,save_money_2};

endmodule // vip_price
