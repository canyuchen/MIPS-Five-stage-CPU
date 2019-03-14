module alu(
  input  wire [11:0] aluop    ,
  input  wire [31:0] alu_in_1 ,
  input  wire [31:0] alu_in_2 ,
  output wire [31:0] result
);

wire        alu_add        ;
wire        alu_sub        ;
wire        alu_slt        ;
wire        alu_sltu       ;
wire        alu_and        ;
wire        alu_nor        ;
wire        alu_or         ;
wire        alu_xor        ;
wire        alu_sll        ;
wire        alu_srl        ;
wire        alu_sra        ;
wire        alu_lui        ;

wire [31:0] add_sub_result ;
wire [31:0] slt_result     ;
wire [31:0] sltu_result    ;
wire [31:0] and_result     ;
wire [31:0] nor_result     ;
wire [31:0] or_result      ;
wire [31:0] xor_result     ;
wire [31:0] sll_result     ;
wire [31:0] sr_result      ;
wire [31:0] lui_result     ;
wire [63:0] sr64_result    ; 

wire [31:0] adder_1        ;
wire [31:0] adder_2        ;
wire        adder_cin      ;
wire [31:0] adder_result   ;
wire        adder_cout     ;

assign alu_add  = aluop[11];
assign alu_sub  = aluop[10];
assign alu_slt  = aluop[ 9];
assign alu_sltu = aluop[ 8];
assign alu_and  = aluop[ 7];
assign alu_nor  = aluop[ 6];
assign alu_or   = aluop[ 5];
assign alu_xor  = aluop[ 4];
assign alu_sll  = aluop[ 3];
assign alu_srl  = aluop[ 2];
assign alu_sra  = aluop[ 1];
assign alu_lui  = aluop[ 0];

assign and_result = alu_in_1 & alu_in_2;
assign or_result  = alu_in_1 | alu_in_2;
assign nor_result = ~or_result;
assign xor_result = alu_in_1 ^ alu_in_2;
assign lui_result = {alu_in_2[15:0], 16'd0};

assign adder_1    = alu_in_1;
assign adder_2    = alu_in_2 ^ {32{alu_sub | alu_slt | alu_sltu}};
assign adder_cin  = alu_sub | alu_slt | alu_sltu;
assign {adder_cout, adder_result} = adder_1 + adder_2 + adder_cin;

assign add_sub_result    = adder_result;

assign slt_result[31:1]  = 31'd0;
assign slt_result[0]     = (alu_in_1[31] & ~alu_in_2[31])
                         | (~(alu_in_1[31] ^ alu_in_2[31]) & adder_result[31]);

assign sltu_result[31:1] = 31'd0;
assign sltu_result[0]    = ~adder_cout;

assign sll_result  = alu_in_2 << alu_in_1[4:0];

assign sr64_result = {{32{alu_sra & alu_in_2[31]}}, alu_in_2[31:0]} >> alu_in_1[4:0];
assign sr_result   = sr64_result[31:0];

assign result = ({32{alu_add | alu_sub}} & add_sub_result)
              | ({32{alu_slt          }} & slt_result    )
              | ({32{alu_sltu         }} & sltu_result   )
              | ({32{alu_and          }} & and_result    )
              | ({32{alu_nor          }} & nor_result    )
              | ({32{alu_or           }} & or_result     )
              | ({32{alu_xor          }} & xor_result    )
              | ({32{alu_sll          }} & sll_result    )
              | ({32{alu_srl | alu_sra}} & sr_result     )
              | ({32{alu_lui          }} & lui_result    );

endmodule //alu
