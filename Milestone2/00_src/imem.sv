module imem (
    input  logic       /* i_clk,*/ i_reset,
    input  logic [31:0] i_addr,
    output logic [31:0] o_rdata
);

    logic [31:0] mem [0:2047];  // 8KB instruction memory (2000 x 32-bit)

    // Đọc file hex vào bộ nhớ
    initial begin
        $readmemh("./../02_test/isa_4b.hex",mem);
    end

    // Địa chỉ đã căn chỉnh (bỏ qua 2 bit thấp)
    logic [12:0] addr_aligned;
    assign addr_aligned = i_addr[12:2];  // 11 bit để truy cập 2048 word**

    // Đọc đồng bộ
    always_comb  begin
        if (!i_reset) begin
            o_rdata = 32'h0000_0000;
        end else begin
            o_rdata = mem[addr_aligned];
        end
    end
endmodule
