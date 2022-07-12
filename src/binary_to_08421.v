module binary_to_08421 (input wire [31:0] in,
                        output wire [19:0] out);

wire[4:0] qianwei; // 千位
wire[4:0] baiwei;  // 百位
wire[4:0] shiwei;  // 十位
wire[4:0] gewei;
assign gewei   = in%10;
assign shiwei  = (in/10)%10;
assign baiwei  = (in/100)%10;
assign qianwei = (in/1000)%10;
assign out     = {qianwei,baiwei,shiwei,gewei};

endmodule // bianry_to_08421
