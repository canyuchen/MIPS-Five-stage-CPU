module mips_pc_calculation(
    input  wire [31:0] ex_instruction,
    input  wire [31:0] cp0_epc       ,
    input  wire [31:0] de_instruction,
    input  wire        fe_allowin    ,
    input  wire        fe_valid      ,
    input  wire [31:0] fe_pc         ,
    input  wire [31:0] hd_rf_rdata_1 ,
    input  wire [31:0] hd_rf_rdata_2 ,
    output wire [31:0] nextpc                      
);

wire [5:0] func   = de_instruction[ 5: 0];
wire [5:0] op     = de_instruction[31:26];
wire [4:0] rt     = de_instruction[20:16];

wire de_is_beq    = op==6'b000100 && (hd_rf_rdata_1 == hd_rf_rdata_2);
wire de_is_bne    = op==6'b000101 && (hd_rf_rdata_1 != hd_rf_rdata_2);
wire de_is_j      = op==6'b000010;
wire de_is_jal    = op==6'b000011;
wire de_is_jr     = op==6'b000000 && func==6'b001_000;
wire de_is_bgez   = op==6'b000001 && rt==5'b00001 && (hd_rf_rdata_1[31]==1'b0);
wire de_is_bgtz   = op==6'b000111 && rt==5'b00000 && (hd_rf_rdata_1[31]==1'b0 && hd_rf_rdata_1 != 32'd0);
wire de_is_blez   = op==6'b000110 && rt==5'b00000 && (hd_rf_rdata_1[31]==1'b1 || hd_rf_rdata_1 == 32'd0);
wire de_is_bltz   = op==6'b000001 && rt==5'b00000 && (hd_rf_rdata_1[31]==1'b1);
wire de_is_bltzal = op==6'b000001 && rt==5'b10000 && (hd_rf_rdata_1[31]==1'b1);
wire de_is_bgezal = op==6'b000001 && rt==5'b10001 && (hd_rf_rdata_1[31]==1'b0);
wire de_is_jalr   = op==6'b000000 && rt==5'b00000 && func==6'b001001;

wire [15:0] de_br_offset      = {de_instruction[13:0], 2'b0};
wire [25:0] de_j_jal_index    = de_instruction[25:0];
wire [31:0] de_jr_jalr_target = hd_rf_rdata_1;
wire        de_br_cond        = de_is_bne | de_is_beq | de_is_bgez | de_is_bgtz | de_is_blez | de_is_bltz | de_is_bltzal | de_is_bgezal;
wire        de_pc_4_cond      = !de_br_cond & !de_is_j & !de_is_jal & !de_is_jr & !de_is_jalr;

//exception, in EX_step to decide
// assign is_syscall = EX_Instruction[31:26]==6'd0 && EX_Instruction[5:0]==6'b001100;
// assign exception_commit = is_syscall;

wire is_eret = ex_instruction[31:0]=={6'b010000, 1'b1, 19'd0, 6'b011000};
assign eret_commit = is_eret;

assign nextpc = ({32{eret_commit}} | cp0_epc)
              | ({32{!fe_valid}}                                & {32'hbfc00000}                                  )
              | ({32{ fe_valid}} & {32{de_br_cond            }} & (fe_pc + {{16{de_br_offset[15]}}, de_br_offset}))
              | ({32{ fe_valid}} & {32{de_is_j   | de_is_jal }} & {fe_pc[31:28], de_j_jal_index, 2'b0}            )
              | ({32{ fe_valid}} & {32{de_is_jr  | de_is_jalr}} & {de_jr_jalr_target}                             )
              | ({32{ fe_valid}} & {32{de_pc_4_cond          }} & (fe_pc + 32'd4)                                 );                  

endmodule
