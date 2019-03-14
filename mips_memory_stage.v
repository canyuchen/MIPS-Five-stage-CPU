module mips_memory_stage(
    input  wire        clk                , 
    input  wire        rst                , 

    input  wire [31:0] ex_out_op          , //control signals used in MEM, WB stages
    input  wire [ 4:0] ex_rf_waddr        , //reg num of dest operand
    input  wire [31:0] ex_out_value       , //alu result from exe_stage or other intermediate
                                            //value for the following stages
    input  wire [31:0] ex_rf_rdata_2      ,

    input  wire [31:0] data_sram_rdata    ,

    output wire [31:0] mem_out_op         , //control signals used in WB stage
    output reg  [ 4:0] mem_rf_waddr       , //reg num of dest operand
    output wire [31:0] mem_out_value      , //mem_stage final result

    input  wire [31:0] ex_pc              , //pc @execute_stage
    input  wire [31:0] ex_instruction     , //instr code @execute_stage
    output reg  [31:0] mem_pc             , //pc @memory_stage
    output reg  [31:0] mem_instruction    , //instr code @memory_stage

    input wire  [31:0] ex_hi_value        ,
    input wire  [31:0] ex_lo_value        ,
    output reg  [31:0] mem_hi_value       ,
    output reg  [31:0] mem_lo_value       ,
    
    output reg         mem_valid          , 
    input  wire        ex_valid_ready_go  , 
    output wire        mem_allowin        , 
    output wire        mem_valid_ready_go , 
    input  wire        wb_allowin           

);

reg  [31:0] mem_op         ;
reg  [31:0] mem_prev_value ;
wire        op_WBMux       ;
wire        mem_ready_go   ;
wire [ 6:0] op_load        ;

wire [31:0] mem_radta_LB   ;
wire [31:0] mem_radta_LBU  ;
wire [31:0] mem_radta_LH   ;
wire [31:0] mem_radta_LHU  ;
wire [31:0] mem_radta_LWL  ;
wire [31:0] mem_radta_LWR  ;

reg  [31:0] mem_rf_rdata_2 ;

always @(posedge clk) begin
    if(rst) begin
        mem_rf_waddr   <= 5'd0 ;
        mem_op         <= 22'd0;
        mem_prev_value <= 32'd0;
        mem_hi_value   <= 32'd0;
        mem_lo_value   <= 32'd0;
        mem_rf_rdata_2 <= 32'd0;
    end
    if(ex_valid_ready_go && mem_allowin) begin
        mem_rf_waddr   <= ex_rf_waddr  ;
        mem_op         <= ex_out_op    ;
        mem_prev_value <= ex_out_value ;
        mem_hi_value   <= ex_hi_value  ;
        mem_lo_value   <= ex_lo_value  ;
        mem_rf_rdata_2 <= ex_rf_rdata_2;
    end
end

always @(posedge clk) begin
    if(rst) mem_valid <= 1'b0;
    else if(mem_allowin) mem_valid <= ex_valid_ready_go;
end

always @(posedge clk)
    if(ex_valid_ready_go && mem_allowin) begin
        mem_pc   <= ex_pc;
        mem_instruction <= ex_instruction;
    end    

assign op_WBMux           = mem_op[12];
assign op_load            = mem_op[26:20];

assign mem_out_op         = mem_op;

assign mem_radta_LB       = ({32{mem_prev_value[1:0]==2'b00}} & {{24{data_sram_rdata[ 7]}},data_sram_rdata[ 7: 0]})
                          | ({32{mem_prev_value[1:0]==2'b01}} & {{24{data_sram_rdata[15]}},data_sram_rdata[15: 8]})
                          | ({32{mem_prev_value[1:0]==2'b10}} & {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]})
                          | ({32{mem_prev_value[1:0]==2'b11}} & {{24{data_sram_rdata[31]}},data_sram_rdata[31:24]});

assign mem_radta_LBU      = ({32{mem_prev_value[1:0]==2'b00}} & {{24'd0},data_sram_rdata[ 7: 0]})
                          | ({32{mem_prev_value[1:0]==2'b01}} & {{24'd0},data_sram_rdata[15: 8]})
                          | ({32{mem_prev_value[1:0]==2'b10}} & {{24'd0},data_sram_rdata[23:16]})
                          | ({32{mem_prev_value[1:0]==2'b11}} & {{24'd0},data_sram_rdata[31:24]});

assign mem_radta_LH       = ({32{mem_prev_value[1]==1'b0}} & {{16{data_sram_rdata[15]}},data_sram_rdata[15: 0]})               
                          | ({32{mem_prev_value[1]==1'b1}} & {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]});

assign mem_radta_LHU      = ({32{mem_prev_value[1]==1'b0}} & {{16'd0},data_sram_rdata[15: 0]})
                          | ({32{mem_prev_value[1]==1'b1}} & {{16'd0},data_sram_rdata[31:16]});

assign mem_radta_LWL      = ({32{mem_prev_value[1:0]==2'b00}} & {data_sram_rdata[ 7: 0],mem_rf_rdata_2[23:0]})
                          | ({32{mem_prev_value[1:0]==2'b01}} & {data_sram_rdata[15: 0],mem_rf_rdata_2[15:0]})
                          | ({32{mem_prev_value[1:0]==2'b10}} & {data_sram_rdata[23: 0],mem_rf_rdata_2[ 7:0]})
                          | ({32{mem_prev_value[1:0]==2'b11}} &  data_sram_rdata                             );

assign mem_radta_LWR      = ({32{mem_prev_value[1:0]==2'b00}} & data_sram_rdata                               )
                          | ({32{mem_prev_value[1:0]==2'b01}} & {mem_rf_rdata_2[31:24],data_sram_rdata[31: 8]})
                          | ({32{mem_prev_value[1:0]==2'b10}} & {mem_rf_rdata_2[31:16],data_sram_rdata[31:16]})
                          | ({32{mem_prev_value[1:0]==2'b11}} & {mem_rf_rdata_2[31: 8],data_sram_rdata[31:24]});

assign mem_out_value      = ({32{!op_WBMux}} & mem_prev_value                    )
                          | ({32{ op_WBMux}} & {32{op_load[0]}} & data_sram_rdata)
                          | ({32{ op_WBMux}} & {32{op_load[1]}} & mem_radta_LB   )
                          | ({32{ op_WBMux}} & {32{op_load[2]}} & mem_radta_LBU  )
                          | ({32{ op_WBMux}} & {32{op_load[3]}} & mem_radta_LH   )
                          | ({32{ op_WBMux}} & {32{op_load[4]}} & mem_radta_LHU  )
                          | ({32{ op_WBMux}} & {32{op_load[5]}} & mem_radta_LWL  )
                          | ({32{ op_WBMux}} & {32{op_load[6]}} & mem_radta_LWR  );    

assign mem_ready_go       = 1'b1;
assign mem_allowin        = !mem_valid || mem_ready_go && wb_allowin;
assign mem_valid_ready_go = mem_valid && mem_ready_go;

endmodule //memory_stage
