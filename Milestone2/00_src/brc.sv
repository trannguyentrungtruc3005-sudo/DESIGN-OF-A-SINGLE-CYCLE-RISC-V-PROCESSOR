module brc (
  input  logic [31:0] i_rs1_data,
  input  logic [31:0] i_rs2_data,
  input  logic        i_br_un,      
  output logic        o_br_equal,   
  output logic        o_br_less     
);

  logic [31:0] diff;
  logic        co_sub;             
  add_sub u_sub (
    .x    (i_rs1_data),
    .y    (i_rs2_data),   
    .c_in (1'b1),         
    .s    (diff),
    .c_out(co_sub)
  );
  //Equal: XOR + reduction NOR
  assign o_br_equal = ~(|(i_rs1_data ^ i_rs2_data));

  //Unsigned less: borrow => carry_out = 0
  logic lt_u;
  assign lt_u = ~co_sub;

  //Signed less
  logic a31, b31, s31, lt_s;
  assign a31 = i_rs1_data[31];
  assign b31 = i_rs2_data[31];
  assign s31 = diff[31];
  assign lt_s = (a31 ^ b31) ? a31 : s31;
  assign o_br_less = (i_br_un) ? lt_s : lt_u;

endmodule
