module div(
    input  wire        div_clk     ,
    input  wire        rst         ,
    input  wire        div         ,
    input  wire        div_signed  ,
    input  wire [31:0] x           ,
    input  wire [31:0] y           ,
    output wire [31:0] s           , 
    output wire [31:0] r           ,
    output wire        complete
);

reg  [63:0] div_result_reg;
reg  [31:0] div_s_reg     ;
integer     count         ;
        
always @(posedge div_clk) begin
    count <= (rst || count == 33) ? 0 : (div) ? count + 1 : 0;
end

always @(posedge div_clk) begin
    div_result_reg <= div_result;
    div_s_reg <= div_s;
end

wire [31:0] y_unsigned = ({32{ div_signed &&  y[31]}} & (~y + 1) )
                       | ({32{!div_signed || !y[31]}} & y        );
wire [31:0] x_unsigned = ({32{ div_signed &&  x[31]}} & (~x + 1) )
                       | ({32{!div_signed || !x[31]}} & x        );
wire [63:0] div_x_64   = {32'b0, x_unsigned}  ;
wire [32:0] div_y_33   = {1'b0, y_unsigned}   ;
wire [31:0] div_r      = div_result_reg[63:32];
wire [63:0] div_result = ({64{!rst}} & {64{count == 0}} & div_x_64                                                                                                 )    
                       | ({64{!rst}} & {64{count != 0}} & {64{div_result_reg[63:31] < div_y_33}}  & (div_result_reg << 1)                                          )
                       | ({64{!rst}} & {64{count != 0}} & {64{div_result_reg[63:31] >= div_y_33}} & ({div_result_reg[63:31] - div_y_33, div_result_reg[30:0]} << 1));
wire [31:0] div_s      = ({32{!rst}} & {32{count != 0}} & {32{div_result_reg[63:31] < div_y_33}}  & (div_s_reg << 1)          )
                       | ({32{!rst}} & {32{count != 0}} & {32{div_result_reg[63:31] >= div_y_33}} & ((div_s_reg << 1) + 32'd1));

assign complete        = (count == 'd33);

assign s               = ({32{count == 'd33}} & {32{ ~div_signed  ||  x[31] ^ y[31] == 1'b0 }} & div_s_reg           )
                       | ({32{count == 'd33}} & {32{  div_signed  &&  x[31] ^ y[31] == 1'b1 }} & (~div_s_reg + 32'd1));
                         
assign r               = ({32{count == 'd33}} & {32{ ~div_signed  || ~x[31]}} &  div_r          )
                       | ({32{count == 'd33}} & {32{  div_signed  &&  x[31]}} & (~div_r + 32'd1)); 
        
endmodule //div
