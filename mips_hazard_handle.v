module mips_hazard_handle(
    input  wire        clk              ,
    input  wire        rst              ,

    input  wire [31:0] hd_instruction   ,
    input  wire        ex_valid         ,
    input  wire [31:0] ex_op            ,
    input  wire [ 4:0] ex_rf_waddr      ,
    input  wire        mem_valid        ,
    input  wire [31:0] mem_op           ,
    input  wire [ 4:0] mem_rf_waddr     ,
    input  wire        wb_valid         ,
    input  wire [ 4:0] wb_rf_waddr      ,
    input  wire [31:0] wb_op            ,

    output wire [ 4:0] de_rf_raddr_1    ,
    input  wire [31:0] de_rf_rdata_1    ,
    output wire [ 4:0] de_rf_raddr_2    ,
    input  wire [31:0] de_rf_rdata_2    ,

    input  wire [31:0] ex_out_value     ,
    input  wire [31:0] mem_out_value    ,
    input  wire [31:0] wb_value         ,

    input  wire [31:0] ex_hi_value      ,
    input  wire [31:0] ex_lo_value      ,
    input  wire [31:0] mem_hi_value     ,
    input  wire [31:0] mem_lo_value     ,
    input  wire [31:0] wb_hi_value      ,
    input  wire [31:0] wb_lo_value      ,
    output wire [31:0] hd_hi_value      ,
    output wire [31:0] hd_lo_value      ,

    input  wire        ex_mult_complete ,
    input  wire        ex_div_complete  ,

    output wire [31:0] hd_rf_rdata_1    ,
    output wire [31:0] hd_rf_rdata_2    ,
    output wire        hd_wait 
);

wire        hazard_1      ;
wire        hazard_2      ;
wire        ex_lw         ;
wire        mem_lw        ;

assign hazard_1      = de_rf_raddr_1 != 5'd0;
assign hazard_2      = de_rf_raddr_2 != 5'd0; 

assign ex_lw         = ex_op[14]  & ~ex_op[13];
assign mem_lw        = mem_op[14] & ~mem_op[13]; 
assign wb_lw         = wb_op[14]  & ~wb_op[13];

wire ex_hazard_1     = hazard_1  && ex_valid  && (de_rf_raddr_1 == ex_rf_waddr );
wire ex_hazard_2     = hazard_2  && ex_valid  && (de_rf_raddr_2 == ex_rf_waddr );
wire mem_hazard_1    = hazard_1  && mem_valid && (de_rf_raddr_1 == mem_rf_waddr);
wire mem_hazard_2    = hazard_2  && mem_valid && (de_rf_raddr_2 == mem_rf_waddr);
wire wb_hazard_1     = hazard_1  && wb_valid  && (de_rf_raddr_1 == wb_rf_waddr );
wire wb_hazard_2     = hazard_2  && wb_valid  && (de_rf_raddr_2 == wb_rf_waddr );

assign de_rf_raddr_1 = hd_instruction[25:21];
assign de_rf_raddr_2 = hd_instruction[20:16];

//forwarding
//only decided by the the most close instruction

assign hd_rf_rdata_1 = ({32{ ex_hazard_1}} & ex_out_value                                             )
                     | ({32{!ex_hazard_1}} & {32{ mem_hazard_1}} & mem_out_value                      )
                     | ({32{!ex_hazard_1}} & {32{!mem_hazard_1}} & {32{ wb_hazard_1}} & wb_value      ) 
                     | ({32{!ex_hazard_1}} & {32{!mem_hazard_1}} & {32{!wb_hazard_1}} & de_rf_rdata_1 );
assign hd_rf_rdata_2 = ({32{ ex_hazard_2}} & ex_out_value                                             )
                     | ({32{!ex_hazard_2}} & {32{ mem_hazard_2}} & mem_out_value                      )
                     | ({32{!ex_hazard_2}} & {32{!mem_hazard_2}} & {32{ wb_hazard_2}} & wb_value      ) 
                     | ({32{!ex_hazard_2}} & {32{!mem_hazard_2}} & {32{!wb_hazard_2}} & de_rf_rdata_2 );
    
wire ex_hi_sign      = ex_op[19]; 
wire ex_lo_sign      = ex_op[18];
wire mem_hi_sign     = mem_op[19];
wire mem_lo_sign     = mem_op[18];
wire wb_hi_sign      = wb_op[19];
wire wb_lo_sign      = wb_op[18];
wire ex_mul_sign     = ex_op[17];
wire ex_div_sign     = ex_op[16];

reg [31:0] hd_hi_reg;
reg [31:0] hd_lo_reg;

always @(posedge clk) begin
    if(rst) begin
        hd_hi_reg <= 32'd0;
    end
    else if(wb_hi_sign & wb_valid) begin
        hd_hi_reg <= wb_hi_value;
    end
end

always @(posedge clk) begin
    if(rst) begin
        hd_lo_reg <= 32'd0;
    end
    else if(wb_lo_sign & wb_valid) begin
        hd_lo_reg <= wb_lo_value;
    end
end

assign hd_hi_value   = ({32{ ex_mul_sign}} & {32{ex_mult_complete}} & {32{ex_hi_sign }} & {32{ex_valid }} & ex_hi_value)
                     | ({32{ ex_div_sign}} & {32{ex_div_complete }} & {32{ex_hi_sign }} & {32{ex_valid }} & ex_hi_value)
                     | ({32{!ex_mul_sign}} & {32{!ex_div_sign}} & {32{ex_hi_sign }} & {32{ex_valid }} & ex_hi_value    )
                     | ({32{!ex_mul_sign}} & {32{!ex_div_sign}} & {32{mem_hi_sign}} & {32{mem_valid}} & mem_hi_value   )
                     | ({32{!ex_mul_sign}} & {32{!ex_div_sign}} & {32{wb_hi_sign }} & {32{wb_valid }} & wb_hi_value    )
                     | ({32{!ex_mul_sign&!ex_div_sign&!ex_hi_sign&!mem_hi_sign&!wb_hi_sign}} & hd_hi_reg               )
                     ;   
assign hd_lo_value   = ({32{ ex_mul_sign}} & {32{ex_mult_complete}} & {32{ex_lo_sign }} & {32{ex_valid }} & ex_lo_value)
                     | ({32{ ex_div_sign}} & {32{ex_div_complete }} & {32{ex_lo_sign }} & {32{ex_valid }} & ex_lo_value)
                     | ({32{!ex_mul_sign}} & {32{!ex_div_sign}} & {32{ex_lo_sign }} & {32{ex_valid }} & ex_lo_value    )
                     | ({32{!ex_mul_sign}} & {32{!ex_div_sign}} & {32{mem_lo_sign}} & {32{mem_valid}} & mem_lo_value   )
                     | ({32{!ex_mul_sign}} & {32{!ex_div_sign}} & {32{wb_lo_sign }} & {32{wb_valid }} & wb_lo_value    )
                     | ({32{!ex_mul_sign&!ex_div_sign&!ex_lo_sign&!mem_lo_sign&!wb_lo_sign}} & hd_lo_reg               )
                     ;

//stall
assign hd_wait       = ((ex_hazard_1  ||  ex_hazard_2 ) && ex_valid  && ex_lw )
                     | ((mem_hazard_1 ||  mem_hazard_2) && mem_valid && mem_lw)
                     | ((wb_hazard_1  ||  wb_hazard_2 ) && wb_valid  && wb_lw )
                     | ( ex_mul_sign  && ex_valid && !ex_mult_complete        ) 
                     | ( ex_div_sign  && ex_valid && !ex_div_complete         );

endmodule // hazard_handle
