module imm_gen(
    input logic [2:0] i_immsel,
    input logic [31:0] i_inst,
    output logic [31:0] o_imm
);

    parameter I_type = 3'b000;
    parameter S_type = 3'b001;
    parameter B_type = 3'b010;
    parameter J_type = 3'b100;
    // U_type là các giá trị còn lại

    always_comb begin
        case (i_immsel)
            I_type: begin
                o_imm[0]      = i_inst[20];
                o_imm[4:1]    = i_inst[24:21];
                o_imm[10:5]   = i_inst[30:25];
                o_imm[11]     = i_inst[31];
                o_imm[19:12]  = {8{i_inst[31]}};
                o_imm[31:20]  = {12{i_inst[31]}};
            end
            S_type: begin
                o_imm[0]      = i_inst[7];
                o_imm[4:1]    = i_inst[11:8];
                o_imm[10:5]   = i_inst[30:25];
                o_imm[11]     = i_inst[31];
                o_imm[19:12]  = {8{i_inst[31]}};
                o_imm[31:20]  = {12{i_inst[31]}};
            end
            B_type: begin
                o_imm[0]      = 1'b0;
                o_imm[4:1]    = i_inst[11:8];
                o_imm[10:5]   = i_inst[30:25];
                o_imm[11]     = i_inst[7];
                o_imm[19:12]  = {8{i_inst[31]}};
                o_imm[31:20]  = {12{i_inst[31]}};
            end
            J_type: begin
                o_imm[0]      = 1'b0;
                o_imm[4:1]    = i_inst[24:21];
                o_imm[10:5]   = i_inst[30:25];
                o_imm[11]     = i_inst[20];
                o_imm[19:12]  = i_inst[19:12];
                o_imm[31:20]  = {12{i_inst[31]}};
            end
            default: begin // U_type
                o_imm[0]      = 1'b0;
                o_imm[4:1]    = 4'b0000;
                o_imm[10:5]   = 6'b0000_00;
                o_imm[11]     = 1'b0;
                o_imm[19:12]  = i_inst[19:12];
                o_imm[31:20]  = i_inst[31:20];
            end
        endcase
    end
endmodule