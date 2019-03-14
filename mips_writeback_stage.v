module mips_writeback_stage(
    input  wire        clk                ,
    input  wire        rst                ,

    input  wire [31:0] mem_out_op         , //control signals used in WB stage
    input  wire [ 4:0] mem_rf_waddr       , //reg num of dest operand
    input  wire [31:0] mem_value          , //mem_stage final result

    output wire [ 3:0] wb_rf_wen          , 
    output reg  [ 4:0] wb_rf_waddr        ,
    output wire [31:0] wb_rf_wdata        ,
    output wire [31:0] wb_out_op          ,

    input  wire [31:0] mem_pc             , //pc @memory_stage
    input  wire [31:0] mem_instruction    , //instr code @memory_stage
    output reg  [31:0] wb_pc              ,

    input wire  [31:0] mem_hi_value       ,
    input wire  [31:0] mem_lo_value       ,
    output reg  [31:0] wb_hi_value        ,
    output reg  [31:0] wb_lo_value        ,
    
    output reg         wb_valid           ,
    input  wire        mem_valid_ready_go ,
    output wire        wb_allowin
);

reg  [31:0] wb_op          ;
reg  [31:0] wb_value       ;
reg  [31:0] wb_instruction ;
wire        op_RegWrite    ;

always @(posedge clk) begin
    if(rst) begin
        wb_rf_waddr  <= 5'd0 ;
        wb_op        <= 22'd0;
        wb_value     <= 32'd0;
        wb_hi_value  <= 32'd0;
        wb_lo_value  <= 32'd0;
    end
    if(mem_valid_ready_go && wb_allowin) begin
        wb_rf_waddr  <= mem_rf_waddr;
        wb_op        <= mem_out_op  ;
        wb_value     <= mem_value   ;
        wb_hi_value  <= mem_hi_value;
        wb_lo_value  <= mem_lo_value;
    end
end

always @(posedge clk) begin
    if(rst) wb_valid <= 1'b0;
    else if(wb_allowin) wb_valid <= mem_valid_ready_go;
end

always @(posedge clk)
    if(mem_valid_ready_go && wb_allowin) begin
        wb_pc          <= mem_pc;
        wb_instruction <= mem_instruction;
    end    

assign op_RegWrite = wb_op[15];

assign wb_rf_wen   = {4{wb_valid}} & {4{op_RegWrite}};
assign wb_rf_wdata = wb_value;

assign wb_allowin  = 1'b1;

assign wb_out_op = wb_op;

endmodule //writeback_stage
