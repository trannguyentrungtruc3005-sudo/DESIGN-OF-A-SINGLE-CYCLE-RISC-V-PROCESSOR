module regfile(
  input  logic        i_clk, i_reset, i_rd_wren,
  input  logic [4:0]  i_rs1_addr, i_rs2_addr, i_rd_addr,
  input  logic [31:0] i_rd_data,
  output logic [31:0] o_rs1_data, o_rs2_data
);

  logic [31:0] reg31_0 [31:0];

  always_ff @(posedge i_clk or negedge i_reset) begin
    if (!i_reset) begin
	reg31_0[1] <= 0;
	reg31_0[2] <= 0;
	reg31_0[3] <= 0;
	reg31_0[4] <= 0;
	reg31_0[5] <= 0;
	reg31_0[6] <= 0;
	reg31_0[7] <= 0;
	reg31_0[8] <= 0;
	reg31_0[9] <= 0;
	reg31_0[10] <= 0;
	reg31_0[11] <= 0;
	reg31_0[12] <= 0;
	reg31_0[13] <= 0;
	reg31_0[14] <= 0;
	reg31_0[15] <= 0;
	reg31_0[16] <= 0;
	reg31_0[17] <= 0;
	reg31_0[18] <= 0;
	reg31_0[19] <= 0;
	reg31_0[20] <= 0;
	reg31_0[21] <= 0;
	reg31_0[22] <= 0;
	reg31_0[23] <= 0;
	reg31_0[24] <= 0;
	reg31_0[25] <= 0;
	reg31_0[26] <= 0;
	reg31_0[27] <= 0;
	reg31_0[28] <= 0;
	reg31_0[29] <= 0;
	reg31_0[30] <= 0;
	reg31_0[31] <= 0;
    end else if (i_rd_wren) begin
      if (~(|i_rd_addr))      
        reg31_0[i_rd_addr] <= 32'h0000_0000;
      else
        reg31_0[i_rd_addr] <= i_rd_data;
    end
  end

  // Read register (async)
  assign o_rs1_data = reg31_0[i_rs1_addr];
  assign o_rs2_data = reg31_0[i_rs2_addr];

endmodule