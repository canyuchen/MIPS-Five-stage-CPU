module mips_fetch_stage(
    input  wire        clk                  , 
    input  wire        rst                  ,   

    input  wire [31:0] pc_next              , 
    input  wire [31:0] inst_sram_rdata      ,

    output reg  [31:0] fe_pc                , //fetch_stage pc
    output wire [31:0] fe_instruction       , //instr code sent from fetch_stage

    output reg         fe_valid             , 
    output wire        fe_allowin           , 
    output wire        fe_valid_ready_go    , 
    input  wire        de_allowin             
);

parameter   mips_pc_resetn = 32'hbfc00000;

wire        fe_ready_go;

always @(posedge clk) begin
    if(rst) begin
        fe_pc       <= mips_pc_resetn;
        fe_valid    <= 1'b0;
    end 
    else if(fe_allowin) begin
        fe_pc       <= pc_next;
        fe_valid    <= 1'b1;
    end 
end

assign fe_instruction    = inst_sram_rdata;

assign fe_ready_go       = 1'b1;
assign fe_allowin        = !rst && (!fe_valid || (fe_ready_go && de_allowin));
assign fe_valid_ready_go = fe_valid && fe_ready_go;

endmodule //fetch_stage
