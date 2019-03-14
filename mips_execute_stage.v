module mips_execute_stage(
    input  wire        clk               ,
    input  wire        rst               ,

    input  wire [31:0] de_out_op         , //control signals used in EXE, MEM, WB stages
    input  wire [ 4:0] de_rf_waddr       , //reg No. of dest operand, zero if no dest
    input  wire [31:0] de_alu_in_1       , //value of source operand 1
    input  wire [31:0] de_alu_in_2       , //value of source operand 2
    input  wire [31:0] de_to_mem_value   , //value stored to memory

    output wire [31:0] ex_out_op         , //control signals used in MEM, WB stages
    output reg  [ 4:0] ex_rf_waddr       , //reg num of dest operand
    output wire [31:0] ex_out_value      , //alu result from exe_stage or other intermediate
                                           //value for the following stages
    input  wire [31:0] de_pc             , //pc @decode_stage
    input  wire [31:0] de_instruction    , //instr code @decode_stage

    output reg  [31:0] ex_pc             , //pc @execute_stage
    output reg  [31:0] ex_instruction    , //instr code @execute_stage

    output wire [31:0] ex_hi_value       ,
    output wire [31:0] ex_lo_value       ,

    output wire        ex_mult_complete  ,
    output wire        ex_div_complete   ,

    output reg  [31:0] ex_rf_rdata_2     ,

    output reg  [31:0] cp0_epc           ,

    output reg         ex_valid          ,
    input  wire        de_valid_ready_go ,
    output wire        ex_allowin        ,
    output wire        ex_valid_ready_go ,
    input  wire        mem_allowin       
);

reg  [31:0] ex_op           ;
reg  [31:0] ex_alu_in_1     ;
reg  [31:0] ex_alu_in_2     ;

wire        op_MemEnable    ;
wire        op_MemWrite     ;
wire [11:0] op_aluop        ;
wire        op_Mult         ;  
wire        op_Div          ;  
wire        op_mthi         ;  
wire        op_mtlo         ;  
wire [ 4:0] op_store        ;

wire [31:0] ex_alu_result   ;

wire        ex_ready_go     ;

wire        ex_mult_signed  ;
wire [63:0] ex_mult_result  ;
wire        ex_div_signed   ;
wire [31:0] ex_div_s        ;  
wire [31:0] ex_div_r        ;

wire [31:0] ex_wdata_swl    ;
wire [31:0] ex_wdata_swr    ;
wire [31:0] ex_wdata_sb     ;
wire [31:0] ex_wdata_sh     ;
wire [31:0] ex_store_value  ;

wire [ 3:0] ex_swl_control  ;
wire [ 3:0] ex_swr_control  ;
wire [ 3:0] ex_sb_control   ;
wire [ 3:0] ex_sh_control   ;
wire [ 3:0] ex_store_control;

always @(posedge clk) begin
    if(rst) begin
        ex_rf_waddr     <= 5'd0 ;
        ex_op           <= 16'd0;
        ex_alu_in_1     <= 32'd0;
        ex_alu_in_2     <= 32'd0;
        ex_rf_rdata_2   <= 32'd0;
    end
    if(de_valid_ready_go && ex_allowin) begin
        ex_rf_waddr     <= de_rf_waddr    ;
        ex_op           <= de_out_op      ;
        ex_alu_in_1     <= de_alu_in_1    ;
        ex_alu_in_2     <= de_alu_in_2    ;
        ex_rf_rdata_2   <= de_to_mem_value;
    end
end

always @(posedge clk) begin
    if(rst) ex_valid <= 1'b0;
    else if(ex_allowin) ex_valid <= de_valid_ready_go;
end

always @(posedge clk) begin
    if(de_valid_ready_go && ex_allowin) begin
        ex_pc <= de_pc;
        ex_instruction <= de_instruction;
    end    
end

wire exception_commit;
wire eret_commit;
wire mtc0_wen_status;
wire mtc0_wen_cause;
wire mtc0_wen_epc;
wire [31:0] mtc0_value;
wire is_syscall;
//cp0_status
wire [31:0] cp0_status;

wire        cp0_status_bev;
reg  [7:0]  cp0_status_im;
reg         cp0_status_exl;
reg         cp0_status_ie;

assign cp0_status_bev = 1'b1;
assign cp0_status = { 9'd0,           //31:23
                      cp0_status_bev, //22
					  6'd0,           //21:16
                      cp0_status_im,  //15:8
					  6'd0,           //7:2
					  cp0_status_exl, //1
					  cp0_status_ie   //0
                    };
always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_status_im = 8'd0;
	end
	else if(mtc0_wen_status)
	begin
		cp0_status_im <= mtc0_value[15:8];
	end
end

always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_status_exl <= 1'b0;
	end
	else if(mtc0_wen_status)
	begin
		cp0_status_exl <= mtc0_value[1];
	end
	else if(exception_commit)
	begin
		cp0_status_exl <= 1'b1;
	end
	else if(eret_commit)
	begin
		cp0_status_exl <= 1'b0;
	end
end

always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_status_ie <= 1'b1;
	end
	else if(mtc0_wen_status)
	begin
		cp0_status_ie <= mtc0_value[0];
	end
	else if(exception_commit)
	begin
		cp0_status_ie <= 1'b0;
	end
	else if(eret_commit)
	begin
		cp0_status_ie <= 1'b1;
	end
end

//cp0_epc
reg [31:0] cp0_epc;
reg        cp0_cause_bd;
always @ (posedge clk)begin
	if(~resetn)begin
		cp0_epc <= 32'hbfc00000;
	end
	else if(mtc0_wen_epc)begin
		cp0_epc <= mtc0_value;
	end
	else if(exception_commit)begin
		cp0_epc <= {32{cp0_cause_bd}} & (ex_pc-4) |
				   {32{~cp0_cause_bd}} & ex_pc;
	end
end

//cp0_cause
wire [31:0] cp0_cause;

reg         cp0_cause_ti;
reg  [5:0]  cp0_cause_ip7_2;
reg  [1:0]  cp0_cause_ip1_0;
reg  [4:0]  cp0_cause_exccode;

assign cp0_cause = { cp0_cause_bd,      //31
                     cp0_cause_ti,      //30
					 14'd0,             //29:16
                     cp0_cause_ip7_2,   //15:10
					 cp0_cause_ip1_0,   //9:8
					 1'd0,              //7
					 cp0_cause_exccode, //6:2
					 2'd0               //1:0
                   };
always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_cause_bd = 1'd0;
	end
	else 
	begin
		if(!cp0_status_exl && exception_commit)
		begin
			if(MEM_jp==4'b1000)
			begin
				cp0_cause_bd <= 1'd0;
			end
			else
			begin
				cp0_cause_bd <= 1'd1;
			end
		end
	end
end

always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_cause_ti <= 1'd0;
	end
end

always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_cause_ip7_2 <= 6'd0;
	end
end

always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_cause_ip1_0 <= 2'd0;
	end
	else if(mtc0_wen_cause)
	begin
		cp0_cause_ip1_0 <= mtc0_value[9:8];
	end
end

always @(posedge clk)
begin
	if(~resetn)
	begin
		cp0_cause_exccode <= 1'd0;
	end
	else if(is_syscall)
	begin
		cp0_cause_exccode <= 5'd8;
	end
end

//exception, in EX_step to decide
assign is_syscall = ex_instruction[31:26]==6'd0 && ex_instruction[5:0]==6'b001100;
assign exception_commit = is_syscall;

wire is_eret = ex_instruction[31:0]=={6'b010000, 1'b1, 19'd0, 6'b011000};
assign eret_commit = is_eret;

wire [4:0] c0_rd  = ex_instruction[15:11];
wire [2:0] c0_sel = ex_instruction[2:0];
wire c0_status = c0_rd==5'd12 && c0_sel==3'd0; 
wire c0_cause  = c0_rd==5'd13 && c0_sel==3'd0; 
wire c0_epc    = c0_rd==5'd14 && c0_sel==3'd0; 

wire [5:0] func  = ex_instruction[ 5: 0];
wire [4:0] sa    = ex_instruction[10: 6];
wire [4:0] rd    = ex_instruction[15:11];
wire [4:0] rt    = ex_instruction[20:16];
wire [4:0] rs    = ex_instruction[25:21];
wire [5:0] op    = ex_instruction[31:26];

wire inst_MFC0   = op==6'b010000 && rs==5'd0 && ex_instruction[10:3]==8'd0;
//mfc0
wire [31:0] EX_mfc0_cp0 = {32{c0_status}} & cp0_status |
                          {32{c0_cause}}  & cp0_cause  |
					      {32{c0_epc}}    & cp0_epc    ;

assign op_MemEnable      = ex_op[14];
assign op_MemWrite       = ex_op[13];
assign op_aluop          = ex_op[11:0];
assign op_Mult           = ex_op[17];
assign op_Div            = ex_op[16];
assign op_mthi           = ex_op[19] & !op_Mult & !op_Div;
assign op_mtlo           = ex_op[18] & !op_Mult & !op_Div;
assign op_store          = ex_op[31:27];

assign ex_out_op         = ex_op;
assign ex_out_value      = ({32{ inst_MFC0}} & EX_mfc0_cp0  ) 
                         | ({32{!inst_MFC0}} & ex_alu_result);

assign ex_ready_go       = (op_Mult  & ex_mult_complete)
                         | (op_Div   & ex_div_complete )
                         | (!op_Mult & !op_Div         );
assign ex_allowin        = !ex_valid || (ex_ready_go && mem_allowin);
assign ex_valid_ready_go = ex_valid && ex_ready_go;

assign ex_hi_value       = ({32{op_Mult}} & ex_mult_result[63:32])
                         | ({32{op_Div }} & ex_div_r             )
                         | ({32{op_mthi}} & ex_alu_result        );
assign ex_lo_value       = ({32{op_Mult}} & ex_mult_result[31: 0])
                         | ({32{op_Div }} & ex_div_s             )
                         | ({32{op_mtlo}} & ex_alu_result        );

assign ex_mult_signed = ~ex_instruction[0] & op_Mult;
assign ex_div_signed  = ~ex_instruction[0] & op_Div ;

assign ex_wdata_swl      = ({32{ex_alu_result[1:0]==2'b00}} & {24'd0,ex_rf_rdata_2[31:24]      }) 
                         | ({32{ex_alu_result[1:0]==2'b01}} & {16'd0,ex_rf_rdata_2[31:16]      }) 
                         | ({32{ex_alu_result[1:0]==2'b10}} & { 8'd0,ex_rf_rdata_2[31: 8]      }) 
                         | ({32{ex_alu_result[1:0]==2'b11}} & {      ex_rf_rdata_2             });
assign ex_wdata_swr      = ({32{ex_alu_result[1:0]==2'b00}} & {      ex_rf_rdata_2             }) 
                         | ({32{ex_alu_result[1:0]==2'b01}} & {      ex_rf_rdata_2[23: 0], 8'd0}) 
                         | ({32{ex_alu_result[1:0]==2'b10}} & {      ex_rf_rdata_2[15: 0],16'd0})
                         | ({32{ex_alu_result[1:0]==2'b11}} & {      ex_rf_rdata_2[ 7: 0],24'd0});

assign ex_wdata_sb       = ({32{ex_alu_result[1:0]==2'b00}} & {24'd0,ex_rf_rdata_2[ 7: 0]      })
                         | ({32{ex_alu_result[1:0]==2'b01}} & {16'd0,ex_rf_rdata_2[ 7: 0], 8'd0})
                         | ({32{ex_alu_result[1:0]==2'b10}} & { 8'd0,ex_rf_rdata_2[ 7: 0],16'd0})
                         | ({32{ex_alu_result[1:0]==2'b11}} & {      ex_rf_rdata_2[ 7: 0],24'd0});

assign ex_wdata_sh       = ({32{ex_alu_result[  1]==1'b0 }} & {16'd0,ex_rf_rdata_2[15: 0]      })
                         | ({32{ex_alu_result[  1]==1'b1 }} & {      ex_rf_rdata_2[15: 0],16'd0});

assign ex_store_value    = ({32{op_store[0]}} & ex_rf_rdata_2   )
                         | ({32{op_store[1]}} & ex_wdata_swl    )
                         | ({32{op_store[2]}} & ex_wdata_swr    )
                         | ({32{op_store[3]}} & ex_wdata_sb     )
                         | ({32{op_store[4]}} & ex_wdata_sh     );

assign ex_swl_control    = ({4{ex_alu_result[1:0]==2'b00}} & 4'b0001) 
                         | ({4{ex_alu_result[1:0]==2'b01}} & 4'b0011) 
                         | ({4{ex_alu_result[1:0]==2'b10}} & 4'b0111) 
                         | ({4{ex_alu_result[1:0]==2'b11}} & 4'b1111);
assign ex_swr_control    = ({4{ex_alu_result[1:0]==2'b00}} & 4'b1111) 
                         | ({4{ex_alu_result[1:0]==2'b01}} & 4'b1110) 
                         | ({4{ex_alu_result[1:0]==2'b10}} & 4'b1100)
                         | ({4{ex_alu_result[1:0]==2'b11}} & 4'b1000);
assign ex_sb_control     = ({4{ex_alu_result[1:0]==2'b00}} & 4'b0001)
                         | ({4{ex_alu_result[1:0]==2'b01}} & 4'b0010)
                         | ({4{ex_alu_result[1:0]==2'b10}} & 4'b0100)
                         | ({4{ex_alu_result[1:0]==2'b11}} & 4'b1000);
assign ex_sh_control     = ({4{ex_alu_result[  1]==1'b0 }} & 4'b0011)
                         | ({4{ex_alu_result[  1]==1'b1 }} & 4'b1100);

assign ex_store_control  = ({4{op_store[0]}} & 4'b1111       )
                         | ({4{op_store[1]}} & ex_swl_control)
                         | ({4{op_store[2]}} & ex_swr_control)
                         | ({4{op_store[3]}} & ex_sb_control )
                         | ({4{op_store[4]}} & ex_sh_control );

alu alu
    (
    .aluop      (op_aluop         ), //I, 12
    .alu_in_1   (ex_alu_in_1      ), //I, 32
    .alu_in_2   (ex_alu_in_2      ), //I, 32
    .result     (ex_alu_result    )  //O, 32
    );

mult mult
(
    .mul_clk    (clk              ), // I, 1
    .rst        (rst              ), // I, 1
    .mul        (op_Mult          ), // I, 1
    .mul_signed (ex_mult_signed   ), // I, 1
    .x          (ex_alu_in_1      ), // I, 32
    .y          (ex_alu_in_2      ), // I, 32
    .result     (ex_mult_result   ), // O, 64
    .complete   (ex_mult_complete )  // O, 1
);

div div
(
    .div_clk    (clk              ), // I, 1
    .rst        (rst              ), // I, 1
    .div        (op_Div           ), // I, 1
    .div_signed (ex_div_signed    ), // I, 1
    .x          (ex_alu_in_1      ), // I, 32
    .y          (ex_alu_in_2      ), // I, 32
    .s          (ex_div_s         ), // O, 32
    .r          (ex_div_r         ), // O, 32
    .complete   (ex_div_complete  )  // O, 1
);

endmodule //execute_stage
