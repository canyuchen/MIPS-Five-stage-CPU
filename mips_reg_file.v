module mips_reg_file(
    input         clk    ,
    input  [ 4:0] raddr1 ,
    output [31:0] rdata1 ,

    input  [ 4:0] raddr2 ,
    output [31:0] rdata2 ,

    input  [ 3:0] wen    ,
    input  [ 4:0] waddr  ,
    input  [31:0] wdata
);

reg [31:0] heap [31:0];

assign rdata1 = heap[raddr1];
assign rdata2 = heap[raddr2];

always @(posedge clk)
begin
    heap[0] <= 32'd0;
    if ((|wen) && (|waddr)) begin
        heap[waddr] <= wdata;
    end
end

endmodule //regfile
