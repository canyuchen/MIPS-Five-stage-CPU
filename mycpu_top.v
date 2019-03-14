`timescale 1ns / 1ps

module mycpu_top(
    input  wire        clk               ,
    input  wire        resetn            ,            //low active
    
    output wire        inst_sram_en      ,
    output wire [ 3:0] inst_sram_wen     ,
    output wire [31:0] inst_sram_addr    ,
    output wire [31:0] inst_sram_wdata   ,
    input  wire [31:0] inst_sram_rdata   ,
    
    output wire        data_sram_en      ,
    output wire [ 3:0] data_sram_wen     ,
    output wire [31:0] data_sram_addr    ,
    output wire [31:0] data_sram_wdata   ,
    input  wire [31:0] data_sram_rdata   ,
    
    output wire [31:0] debug_wb_pc       ,
    output wire [ 3:0] debug_wb_rf_wen   ,
    output wire [ 4:0] debug_wb_rf_wnum  ,
    output wire [31:0] debug_wb_rf_wdata
);

wire [31:0] mips_pc_next            ;

wire [31:0] mips_fe_pc              ;
wire [31:0] mips_fe_instruction     ;
wire        mips_fe_allowin         ;
wire        mips_fe_valid_ready_go  ;
wire        mips_fe_valid           ;

wire [ 4:0] mips_de_rf_raddr_1      ;
wire [ 4:0] mips_de_rf_raddr_2      ;
wire [31:0] mips_de_rf_rdata_1      ;
wire [31:0] mips_de_rf_rdata_2      ;
wire [31:0] mips_de_pc              ;
wire [31:0] mips_de_instruction     ;
wire        mips_de_valid           ; 
wire        mips_de_allowin         ; 
wire        mips_de_valid_ready_go  ;

wire [31:0] mips_de_out_op          ;
wire [ 4:0] mips_de_rf_waddr        ;
wire [31:0] mips_de_alu_in_1        ;
wire [31:0] mips_de_alu_in_2        ;
wire [31:0] mips_de_to_mem_value    ;

wire [31:0] mips_ex_out_op          ;
wire [ 4:0] mips_ex_rf_waddr        ;
wire [31:0] mips_ex_value           ;
wire [31:0] mips_ex_pc              ;
wire [31:0] mips_ex_instruction     ;
wire        mips_ex_valid           ;
wire        mips_ex_allowin         ;
wire        mips_ex_valid_ready_go  ;
wire [31:0] mips_ex_rf_rdata_2      ;

wire [31:0] mips_mem_out_op         ;
wire [ 4:0] mips_mem_rf_waddr       ;
wire [31:0] mips_mem_value          ;
wire [31:0] mips_mem_pc             ;
wire [31:0] mips_mem_instruction    ;
wire        mips_mem_valid          ;
wire        mips_mem_allowin        ;
wire        mips_mem_valid_ready_go ;

wire [31:0] mips_wb_out_op          ;
wire [ 3:0] mips_wb_rf_wen          ;
wire [ 4:0] mips_wb_rf_waddr        ;
wire [31:0] mips_wb_rf_wdata        ;
wire [31:0] mips_wb_pc              ;
wire        mips_wb_valid           ;
wire        mips_wb_allowin         ;

wire [31:0] mips_hd_instruction     ;
wire [31:0] mips_hd_rf_rdata_1      ;
wire [31:0] mips_hd_rf_rdata_2      ;
wire        mips_hd_wait            ;

wire [31:0] mips_hd_hi_value        ;
wire [31:0] mips_hd_lo_value        ;

wire [31:0] mips_ex_hi_value        ;     
wire [31:0] mips_ex_lo_value        ;     
wire        mips_ex_mult_complete   ;
wire        mips_ex_div_complete    ;
wire [31:0] mips_mem_hi_value       ; 
wire [31:0] mips_mem_lo_value       ; 
wire [31:0] mips_wb_hi_value        ; 
wire [31:0] mips_wb_lo_value        ; 

assign inst_sram_wen     = 4'b0                     ;
assign inst_sram_wdata   = 32'b0                    ;
assign inst_sram_en      = mips_fe_allowin          ;
assign inst_sram_addr    = mips_pc_next             ;

assign debug_wb_pc       = mips_wb_pc               ;
assign debug_wb_rf_wen   = mips_wb_rf_wen           ;
assign debug_wb_rf_wnum  = mips_wb_rf_waddr         ;
assign debug_wb_rf_wdata = mips_wb_rf_wdata         ;

assign data_sram_en      = ex_stage.ex_valid 
                         & ex_stage.op_MemEnable    ;
assign data_sram_wen     = {4{ex_stage.ex_valid}} 
                         & ex_stage.ex_store_control;
assign data_sram_addr    = ex_stage.ex_alu_result   ;
assign data_sram_wdata   = ex_stage.ex_store_value  ;

wire mips_cp0_epc;

mips_pc_calculation pc_calculation
    (
    .ex_instruction     (mips_ex_instruction     ), //I, 32
    .cp0_epc            (mips_cp0_epc            ), //I, 32

    .de_instruction     (mips_de_instruction     ), //I, 32
    .nextpc             (mips_pc_next            ), //O, 32
    .fe_allowin         (mips_fe_allowin         ), //I, 1
    .fe_valid           (mips_fe_valid           ), //I ,1
    .fe_pc              (mips_fe_pc              ), //I, 32
    .hd_rf_rdata_1      (mips_hd_rf_rdata_1      ), //I, 32
    .hd_rf_rdata_2      (mips_hd_rf_rdata_2      )  //I, 32
    );

mips_fetch_stage fe_stage
    (
    .clk                (clk                     ), //I, 1
    .rst                (!resetn                 ), //I, 1

    .pc_next            (mips_pc_next            ), //I, 32

    .inst_sram_rdata    (inst_sram_rdata         ), //I, 32

    .fe_pc              (mips_fe_pc              ), //O, 32
    .fe_instruction     (mips_fe_instruction     ), //O, 32
    
    .fe_valid           (mips_fe_valid           ), //O, 1
    .fe_allowin         (mips_fe_allowin         ), //O, 1
    .fe_valid_ready_go  (mips_fe_valid_ready_go  ), //O, 1
    .de_allowin         (mips_de_allowin         )  //I, 1
    );    

mips_decode_stage de_stage
(
    .clk                (clk                      ), //I, 1
    .rst                (!resetn                  ), //I, 1

    .ex_instruction     (mips_ex_instruction      ), //I, 32

    .fe_pc              (mips_fe_pc               ), //I, 32
    .fe_instruction     (mips_fe_instruction      ), //I, 32
    
    .hd_rf_rdata_1      (mips_hd_rf_rdata_1       ), //I, 32
    .hd_rf_rdata_2      (mips_hd_rf_rdata_2       ), //I, 32
    .hd_wait            (mips_hd_wait             ), //I, 1
    
    .de_out_op          (mips_de_out_op           ), //O, 16
    .de_rf_waddr        (mips_de_rf_waddr         ), //O, 5
    .de_alu_in_1        (mips_de_alu_in_1         ), //O, 32
    .de_alu_in_2        (mips_de_alu_in_2         ), //O, 32
    .de_to_mem_value    (mips_de_to_mem_value     ), //O, 32

    .de_pc              (mips_de_pc               ), //O, 32
    .de_instruction     (mips_de_instruction      ), //O, 32

    .hd_hi_value        (mips_hd_hi_value         ), //I, 32
    .hd_lo_value        (mips_hd_lo_value         ), //I, 32

    .de_valid           (mips_de_valid            ), //O, 1
    .fe_valid_ready_go  (mips_fe_valid_ready_go   ), //I, 1
    .de_allowin         (mips_de_allowin          ), //O, 1
    .de_valid_ready_go  (mips_de_valid_ready_go   ), //O, 1
    .ex_allowin         (mips_ex_allowin          )  //I, 1
);

mips_execute_stage ex_stage
    (
    .clk                (clk                     ), //I, 1
    .rst                (!resetn                 ), //I, 1

    .cp0_epc            (mips_cp0_epc            ), //O, 32

    .de_out_op          (mips_de_out_op          ), //I, 16
    .de_rf_waddr        (mips_de_rf_waddr        ), //I, 5
    .de_alu_in_1        (mips_de_alu_in_1        ), //I, 32
    .de_alu_in_2        (mips_de_alu_in_2        ), //I, 32
    .de_to_mem_value    (mips_de_to_mem_value    ), //I, 32

    .ex_out_op          (mips_ex_out_op          ), //O, 16
    .ex_rf_waddr        (mips_ex_rf_waddr        ), //O, 5
    .ex_out_value       (mips_ex_value           ), //O, 32

    .de_pc              (mips_de_pc              ), //I, 32
    .de_instruction     (mips_de_instruction     ), //I, 32
    .ex_pc              (mips_ex_pc              ), //O, 32
    .ex_instruction     (mips_ex_instruction     ), //O, 32

    .ex_hi_value        (mips_ex_hi_value        ), //O, 32
    .ex_lo_value        (mips_ex_lo_value        ), //O, 32

    .ex_mult_complete   (mips_ex_mult_complete   ), //O, 1
    .ex_div_complete    (mips_ex_div_complete    ), //O, 1

    .ex_rf_rdata_2      (mips_ex_rf_rdata_2      ), //O, 32

    .ex_valid           (mips_ex_valid           ), //O, 1
    .de_valid_ready_go  (mips_de_valid_ready_go  ), //I, 1
    .ex_allowin         (mips_ex_allowin         ), //O, 1
    .ex_valid_ready_go  (mips_ex_valid_ready_go  ), //O, 1
    .mem_allowin        (mips_mem_allowin        )  //I, 1
    );


mips_memory_stage mem_stage
    (
    .clk                (clk                     ), //I, 1
    .rst                (!resetn                 ), //I, 1

    .ex_out_op          (mips_ex_out_op          ), //I, 16
    .ex_rf_waddr        (mips_ex_rf_waddr        ), //I, 5
    .ex_out_value       (mips_ex_value           ), //I, 32
    .ex_rf_rdata_2      (mips_ex_rf_rdata_2      ), //I, 32

    .data_sram_rdata    (data_sram_rdata         ), //I, 32

    .mem_out_op         (mips_mem_out_op         ), //O, 16
    .mem_rf_waddr       (mips_mem_rf_waddr       ), //O, 5
    .mem_out_value      (mips_mem_value          ), //O, 32

    .ex_pc              (mips_ex_pc              ), //I, 32
    .ex_instruction     (mips_ex_instruction     ), //I, 32
    .mem_pc             (mips_mem_pc             ), //O, 32
    .mem_instruction    (mips_mem_instruction    ), //O, 32

    .ex_hi_value        (mips_ex_hi_value        ), //I, 32
    .ex_lo_value        (mips_ex_lo_value        ), //I, 32
    .mem_hi_value       (mips_mem_hi_value       ), //O, 32
    .mem_lo_value       (mips_mem_lo_value       ), //O, 32

    .mem_valid          (mips_mem_valid          ), //O, 1
    .ex_valid_ready_go  (mips_ex_valid_ready_go  ), //I, 1
    .mem_allowin        (mips_mem_allowin        ), //O, 1
    .mem_valid_ready_go (mips_mem_valid_ready_go ), //O, 1
    .wb_allowin         (mips_wb_allowin         )  //I, 1
    );


mips_writeback_stage wb_stage
    (
    .clk                (clk                     ), //I, 1
    .rst                (!resetn                 ), //I, 1

    .mem_out_op         (mips_mem_out_op         ), //I, 16
    .mem_rf_waddr       (mips_mem_rf_waddr       ), //I, 5
    .mem_value          (mips_mem_value          ), //I, 32

    .wb_rf_wen          (mips_wb_rf_wen          ), //O, 1
    .wb_rf_waddr        (mips_wb_rf_waddr        ), //O, 5
    .wb_rf_wdata        (mips_wb_rf_wdata        ), //O, 32
    .wb_out_op          (mips_wb_out_op          ), //O, 32

    .mem_pc             (mips_mem_pc             ), //I, 32
    .mem_instruction    (mips_mem_instruction    ), //I, 32
    .wb_pc              (mips_wb_pc              ), //O, 32

    .mem_hi_value       (mips_mem_hi_value       ), //I, 32
    .mem_lo_value       (mips_mem_lo_value       ), //I, 32
    .wb_hi_value        (mips_wb_hi_value        ), //O, 32
    .wb_lo_value        (mips_wb_lo_value        ), //O, 32

    .wb_valid           (mips_wb_valid           ), //O, 1
    .mem_valid_ready_go (mips_mem_valid_ready_go ), //I, 1
    .wb_allowin         (mips_wb_allowin         )  //O, 1
    );

mips_reg_file reg_file
(
    .clk                (clk                     ), //I, 1,

    .raddr1             (mips_de_rf_raddr_1      ), //I, 5,
    .rdata1             (mips_de_rf_rdata_1      ), //O, 32,

    .raddr2             (mips_de_rf_raddr_2      ), //I, 5,
    .rdata2             (mips_de_rf_rdata_2      ), //O, 32,

    .wen                (mips_wb_rf_wen          ), //I, 1,
    .waddr              (mips_wb_rf_waddr        ), //I, 5 ,
    .wdata              (mips_wb_rf_wdata        )  //I, 32 
);

mips_hazard_handle hazard_handle
(
    .clk                (clk                     ), //I, 1,
    .rst                (!resetn                 ), //I, 1

    .hd_instruction     (mips_de_instruction     ), //I, 32
    .ex_valid           (mips_ex_valid           ), //I, 1
    .ex_op              (mips_ex_out_op          ), //I, 16
    .ex_rf_waddr        (mips_ex_rf_waddr        ), //I, 5
    .mem_valid          (mips_mem_valid          ), //I, 1
    .mem_op             (mips_mem_out_op         ), //I, 16
    .mem_rf_waddr       (mips_mem_rf_waddr       ), //I, 5
    .wb_valid           (mips_wb_valid           ), //I, 1
    .wb_rf_waddr        (mips_wb_rf_waddr        ), //I, 5
    .wb_op              (mips_wb_out_op          ), //I, 32

    .de_rf_raddr_1      (mips_de_rf_raddr_1      ), //O, 5
    .de_rf_rdata_1      (mips_de_rf_rdata_1      ), //I, 32
    .de_rf_raddr_2      (mips_de_rf_raddr_2      ), //O, 5
    .de_rf_rdata_2      (mips_de_rf_rdata_2      ), //I, 32

    .ex_out_value       (mips_ex_value           ), //I, 32
    .mem_out_value      (mips_mem_value          ), //I, 32
    .wb_value           (mips_wb_rf_wdata        ), //I, 32

    .ex_hi_value        (mips_ex_hi_value        ), //I, 32
    .ex_lo_value        (mips_ex_lo_value        ), //I, 32
    .mem_hi_value       (mips_mem_hi_value       ), //I, 32
    .mem_lo_value       (mips_mem_lo_value       ), //I, 32
    .wb_hi_value        (mips_wb_hi_value        ), //I, 32
    .wb_lo_value        (mips_wb_lo_value        ), //I, 32
    .hd_hi_value        (mips_hd_hi_value        ), //I, 32
    .hd_lo_value        (mips_hd_lo_value        ), //I, 32

    .ex_mult_complete   (mips_ex_mult_complete   ), //I, 1
    .ex_div_complete    (mips_ex_div_complete    ), //I, 1

    .hd_rf_rdata_1      (mips_hd_rf_rdata_1      ), //O, 32
    .hd_rf_rdata_2      (mips_hd_rf_rdata_2      ), //O, 32
    .hd_wait            (mips_hd_wait            )  //O, 1
);

endmodule //mycpu_top







