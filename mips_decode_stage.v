module mips_decode_stage(
    input  wire        clk               ,
    input  wire        rst               ,
        
    input  wire [31:0] fe_pc             ,
    input  wire [31:0] fe_instruction    ,
        
    input  wire [31:0] hd_rf_rdata_1     ,
    input  wire [31:0] hd_rf_rdata_2     ,
    input  wire        hd_wait           ,
        
    output wire [31:0] de_out_op         ,  //control signals used in EXE, MEM, WB stages
    output wire [ 4:0] de_rf_waddr       ,  //reg num of dest operand, zero if no dest
    output wire [31:0] de_alu_in_1       ,  //value of source operand 1
    output wire [31:0] de_alu_in_2       ,  //value of source operand 2
    output wire [31:0] de_to_mem_value   ,  //value stored to memory

    output reg  [31:0] de_pc             ,
    output reg  [31:0] de_instruction    ,  //instr code @decode stage

    input  wire [31:0] hd_hi_value       ,
    input  wire [31:0] hd_lo_value       ,

    input  wire [31:0] ex_instruction    ,

    output reg         de_valid          ,
    input  wire        fe_valid_ready_go ,
    output wire        de_allowin        ,
    output wire        de_valid_ready_go ,
    input  wire        ex_allowin
);

wire        op_RegWrite  ;   // External Op
wire        op_MemEnable ;
wire        op_MemWrite  ;
wire        op_WBMux     ;
wire [11:0] op_aluop     ;
wire        op_HIWrite   ;
wire        op_LOWrite   ;
wire        op_Mult      ;
wire        op_Div       ;
wire [ 6:0] op_load      ;
wire [ 4:0] op_store     ;

wire        op_ALUSrc    ;    // Internal Op
wire        op_ExtendMux ;
wire        op_link      ;

wire        op_shift     ;     // More Op

wire [31:0] sign_extend  ;
wire [31:0] zero_extend  ;

wire        de_ready_go  ;

always @(posedge clk) begin
    if(rst) begin
        de_pc    <= 32'hbfc00000;
        de_instruction  <= 32'd0;
    end
    else if(fe_valid_ready_go && de_allowin) begin
        de_pc    <= fe_pc;
        de_instruction  <= (delay_eret_commit | delay_exception_commit) ? 32'd0 : fe_instruction;
    end
end

always @(posedge clk) begin
    if(rst) begin
        de_valid <= 1'b0;
    end
    else if(de_allowin) begin
        de_valid <= fe_valid_ready_go;
    end
end

//exception, in EX_step to decide
assign is_syscall = EX_Instruction[31:26]==6'd0 && EX_Instruction[5:0]==6'b001100;
assign exception_commit = is_syscall;

wire is_eret = ex_instruction[31:0]=={6'b010000, 1'b1, 19'd0, 6'b011000};
assign eret_commit = is_eret;

reg delay_exception_commit;
reg delay_eret_commit;
always @ (posedge clk)
begin
	if(~resetn)
	begin
		delay_exception_commit <= 1'b0;
	end
	else if(exception_commit)
	begin
		delay_exception_commit <= 1'b1;
	end
	else begin
		delay_exception_commit <= 1'b0;
	end
end
always @ (posedge clk)
begin
	if(~resetn)
	begin
		delay_eret_commit <= 1'b0;
	end
	else if(eret_commit)
	begin
		delay_eret_commit <= 1'b1;
	end
	else begin
		delay_eret_commit <= 1'b0;
	end
end

wire [5:0] func  = de_instruction[ 5: 0];
wire [4:0] sa    = de_instruction[10: 6];
wire [4:0] rd    = de_instruction[15:11];
wire [4:0] rt    = de_instruction[20:16];
wire [4:0] rs    = de_instruction[25:21];
wire [5:0] op    = de_instruction[31:26];

wire inst_addu   = op==6'd0 && func==6'b100_001;
wire inst_or     = op==6'd0 && func==6'b100_101;
wire inst_slt    = op==6'd0 && func==6'b101_010;
wire inst_sll    = op==6'd0 && func==6'b000_000;
wire inst_jr     = op==6'd0 && func==6'b001_000;
wire inst_sltu   = op==6'd0 && func==6'b101_011;
wire inst_add    = op==6'd0 && func==6'b100_000;
wire inst_sub    = op==6'd0 && func==6'b100_010;
wire inst_subu   = op==6'd0 && func==6'b100_011;
wire inst_and    = op==6'd0 && func==6'b100_100;
wire inst_nor    = op==6'd0 && func==6'b100_111;
wire inst_xor    = op==6'd0 && func==6'b100_110;
wire inst_sllv   = op==6'd0 && func==6'b000_100;
wire inst_sra    = op==6'd0 && func==6'b000_011;
wire inst_srav   = op==6'd0 && func==6'b000_111;
wire inst_srl    = op==6'd0 && func==6'b000_010;
wire inst_srlv   = op==6'd0 && func==6'b000_110;

wire inst_special= op==6'd0;

wire inst_bne    = op==6'b000101;
wire inst_beq    = op==6'b000100;
wire inst_addiu  = op==6'b001001;
wire inst_lw     = op==6'b100011;
wire inst_sw     = op==6'b101011;
wire inst_j      = op==6'b000010;
wire inst_jal    = op==6'b000011;
wire inst_lui    = op==6'b001111;
wire inst_slti   = op==6'b001010;
wire inst_sltiu  = op==6'b001011;
wire inst_ori    = op==6'b001101;
wire inst_addi   = op==6'b001000;
wire inst_andi   = op==6'b001100;
wire inst_xori   = op==6'b001110;

wire inst_bgez   = op==6'b000001 && rt==5'b00001;
wire inst_bgtz   = op==6'b000111 && rt==5'b00000;
wire inst_blez   = op==6'b000110 && rt==5'b00000;
wire inst_bltz   = op==6'b000001 && rt==5'b00000;
wire inst_bltzal = op==6'b000001 && rt==5'b10000;
wire inst_bgezal = op==6'b000001 && rt==5'b10001;
wire inst_jalr   = op==6'b000000 && rt==5'b00000 && func==6'b001001;
wire inst_lb     = op==6'b100000;
wire inst_lbu    = op==6'b100100;
wire inst_lh     = op==6'b100001;
wire inst_lhu    = op==6'b100101;
wire inst_lwl    = op==6'b100010;
wire inst_lwr    = op==6'b100110;
wire inst_sb     = op==6'b101000;
wire inst_sh     = op==6'b101001;
wire inst_swl    = op==6'b101010;
wire inst_swr    = op==6'b101110;

wire inst_mfhi   = op==6'd0 && {rs,rt,sa}==15'd0 && func==6'b010000;
wire inst_mflo   = op==6'd0 && {rs,rt,sa}==15'd0 && func==6'b010010;
wire inst_mthi   = op==6'd0 && {rt,rd,sa}==15'd0 && func==6'b010001;
wire inst_mtlo   = op==6'd0 && {rt,rd,sa}==15'd0 && func==6'b010011;

wire inst_mult   = op==6'd0 && {rd,sa   }==10'd0 && func==6'b011000;
wire inst_multu  = op==6'd0 && {rd,sa   }==10'd0 && func==6'b011001;
wire inst_div    = op==6'd0 && {rd,sa   }==10'd0 && func==6'b011010;
wire inst_divu   = op==6'd0 && {rd,sa   }==10'd0 && func==6'b011011;

wire inst_ERET      = op==6'b010000 && rs==5'b10000 && rt==5'd0 && rd==5'd0 && sa==5'd0 && func==6'b011000;
wire inst_MFC0      = op==6'b010000 && rs==5'd0 && de_instruction[10:3]==8'd0;
wire inst_MTC0      = op==6'b010000 && rs==5'b00100 && de_instruction[10:3]==8'd0;
wire inst_SYSCALL   = op==6'd0 && func==6'b001100;

assign op_RegWrite   = inst_MFC0
                     | inst_special
                     | inst_lui  | inst_lw     | inst_slti  | inst_jal | inst_andi | inst_addiu 
                     | inst_sltiu| inst_ori    | inst_addi  | inst_xori
                     | inst_jalr | inst_bltzal | inst_bgezal
                     | inst_lb   | inst_lbu    | inst_lh    | inst_lhu | inst_lwl  | inst_lwr;
assign op_MemEnable  = inst_lw   | inst_sw
                     | inst_lb   | inst_lbu| inst_lh  | inst_lhu | inst_lwl  | inst_lwr
                     | inst_sb   | inst_sh | inst_swl | inst_swr;
assign op_MemWrite   = inst_sw
                     | inst_sb   | inst_sh | inst_swl | inst_swr;
assign op_WBMux      = inst_lw
                     | inst_lb   | inst_lbu| inst_lh  | inst_lhu | inst_lwl  | inst_lwr;

assign op_aluop[ 0]  = inst_lui;
assign op_aluop[ 1]  = inst_sra | inst_srav;
assign op_aluop[ 2]  = inst_srl | inst_srlv;
assign op_aluop[ 3]  = inst_sll | inst_sllv;
assign op_aluop[ 4]  = inst_xor | inst_xori;
assign op_aluop[ 5]  = inst_or  | inst_ori;
assign op_aluop[ 6]  = inst_nor;
assign op_aluop[ 7]  = inst_and | inst_andi;
assign op_aluop[ 8]  = inst_sltu| inst_sltiu;
assign op_aluop[ 9]  = inst_slt | inst_slti;
assign op_aluop[10]  = inst_sub | inst_subu;
assign op_aluop[11]  = inst_add | inst_addu | inst_addiu | inst_lw  | inst_sw      | inst_jal | inst_addi
                     | inst_mfhi| inst_mflo | inst_mthi  | inst_mtlo| op_MemEnable | op_link;

assign op_load[0]    = inst_lw ;
assign op_load[1]    = inst_lb ;
assign op_load[2]    = inst_lbu;
assign op_load[3]    = inst_lh ;
assign op_load[4]    = inst_lhu;
assign op_load[5]    = inst_lwl;
assign op_load[6]    = inst_lwr;

assign op_store[0]   = inst_sw ;
assign op_store[1]   = inst_swl;
assign op_store[2]   = inst_swr;
assign op_store[3]   = inst_sb ;
assign op_store[4]   = inst_sh ;

assign op_HIWrite    = inst_mthi | inst_mult | inst_multu | inst_div  | inst_divu;
assign op_LOWrite    = inst_mtlo | inst_mult | inst_multu | inst_div  | inst_divu;
assign op_Mult       = inst_mult | inst_multu;
assign op_Div        = inst_div  | inst_divu;

assign op_ALUSrc     = inst_lui  | inst_sw | inst_lw  | inst_slti| inst_sltiu| inst_addiu 
                     | inst_jal  | inst_ori| inst_addi| inst_andi| inst_xori | op_MemEnable | op_link;
assign op_ExtendMux  = inst_special 
                     | inst_lui  | inst_beq| inst_bne | inst_lw  | inst_slti | inst_addiu
                     | inst_sltiu| inst_sw | inst_j   | inst_jal | inst_addi | op_MemEnable | op_link;

assign op_shift      = inst_sra | inst_srl | inst_sll;

assign op_link       = inst_jal | inst_jalr| inst_bltzal | inst_bgezal;

assign sign_extend   = {{16{de_instruction[15]}}, de_instruction[15:0]};
assign zero_extend   = {16'b0, de_instruction[15:0]};

assign de_out_op     = {op_store,op_load,op_HIWrite,op_LOWrite,op_Mult,op_Div,op_RegWrite,op_MemEnable,op_MemWrite,op_WBMux,op_aluop};

assign de_rf_waddr   = ({5{ inst_MFC0}}  & de_instruction[20:16]) 
                     | ({5{!inst_MFC0}}  & {5{op_RegWrite}} & {5{ op_link     }} & 5'd31                                             )
                     | ({5{!inst_MFC0}}  & {5{op_RegWrite}} & {5{ inst_special}} & de_instruction[15:11]                             )
                     | ({5{!inst_MFC0}}  & {5{op_RegWrite}} & {5{!op_link     }} & {5{!inst_special}} & de_instruction[20:16]        );

assign de_alu_in_1   = ({32{ op_link  }} & fe_pc                                                                  )
                     | ({32{ op_shift }} & {27'b0, de_instruction[10:6]}                                          )
                     | ({32{ inst_mfhi}} & hd_hi_value                                                            )
                     | ({32{ inst_mflo}} & hd_lo_value                                                            )
                     | ({32{!op_link  }} & {32{!op_shift }} & {32{!inst_mfhi}} & {32{!inst_mflo}} & hd_rf_rdata_1 );

assign de_alu_in_2   = ({32{ op_link  }} & 32'd4                                                                  )
                     | ({32{!op_link  }} & {32{ op_ALUSrc}} & {32{ op_ExtendMux}} & sign_extend                   )
                     | ({32{!op_link  }} & {32{ op_ALUSrc}} & {32{!op_ExtendMux}} & zero_extend                   )
                     | ({32{!op_link  }} & {32{!op_ALUSrc}} & hd_rf_rdata_2                                       );

assign de_to_mem_value   = hd_rf_rdata_2;

assign de_ready_go       = !hd_wait;
assign de_allowin        = !de_valid || de_ready_go && ex_allowin;
assign de_valid_ready_go = de_valid && de_ready_go;

endmodule //decode_stage
