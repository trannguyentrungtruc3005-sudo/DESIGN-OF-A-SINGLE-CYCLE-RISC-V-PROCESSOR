module control_unit (
    input  logic [31:0] i_inst,
    input  logic         i_br_less,  
    input  logic         i_br_equal,    
    output logic [3:0]   o_alu_op,    
    output logic         o_reg_wen,
    output logic         o_alu_a_sel,  // 0:rs1; 1: pc
    output logic         o_alu_b_sel, // 0: rs2; 1: IMM
    output logic [2:0]   o_imm_sel,   // Chọn loại immediate để expand
    output logic [1:0]   o_wb_sel,    // Chọn nguồn dữ liệu Write Back //00:data; 01:ALU, 10:PC
    output logic         o_dmem_we,   // Write Enable cho Data Memory
    output logic         o_br_un,     // Branch Unsigned
    output logic         o_pc_sel,    // Chọn PC tiếp theo
    output logic         o_insn_vld,  // Instruction hợp lệ
    output logic [2:0]   o_lsu_type  
);

    // ===== OPCODES =====
    localparam OP_LOAD     = 7'b0000011; // LB, LH, LW, LBU, LHU
    localparam OP_STORE    = 7'b0100011; // SB, SH, SW
    localparam OP_BRANCH   = 7'b1100011; // BEQ, BNE, BLT, BGE, BLTU, BGEU
    localparam OP_JALR     = 7'b1100111;
    localparam OP_JAL      = 7'b1101111; 
    localparam OP_OP_IMM   = 7'b0010011; // ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    localparam OP_OP       = 7'b0110011; // ADD, SUB, SLT, SLTU, XOR, OR, AND, SLL, SRL, SRA
    localparam OP_LUI      = 7'b0110111; // Load Upper Immediate
    localparam OP_AUIPC    = 7'b0010111; // Add Upper Immediate to PC
    

    // ===== IMMEDIATE TYPES =====
    localparam IMM_I  = 3'b000; // I-type: inst[31:20] -> sign_extend 12-bit
    localparam IMM_S  = 3'b001; // S-type: {inst[31:25], inst[11:7]} -> 12-bit
    localparam IMM_B  = 3'b010; // B-type: {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0} -> 13-bit
    localparam IMM_U  = 3'b011; // U-type: {inst[31:12], 12'b0} -> 32-bit
    localparam IMM_J  = 3'b100; // J-type: {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0} -> 21-bit

    // ===== ALU OPERATIONS =====
    localparam ALU_ADD  = 4'b0000;  // Cộng: result = A + B
    localparam ALU_SUB  = 4'b0001;  // Trừ: result = A - B
    localparam ALU_SLT  = 4'b0010;  // Set Less Than (signed): result = (A < B) ? 1 : 0
    localparam ALU_SLTU = 4'b0011;  // Set Less Than Unsigned: result = (A < B) ? 1 : 0
    localparam ALU_XOR  = 4'b0100;  // XOR: result = A ^ B
    localparam ALU_OR   = 4'b0101;  // OR: result = A | B
    localparam ALU_AND  = 4'b0110;  // AND: result = A & B
    localparam ALU_SLL  = 4'b0111;  // Shift Left Logical: result = A << B[4:0]
    localparam ALU_SRL  = 4'b1000;  // Shift Right Logical: result = A >> B[4:0] (zero fill)
    localparam ALU_SRA  = 4'b1001;  // Shift Right Arithmetic: result = A >>> B[4:0] (sign extend)
    localparam ALU_COPY_B = 4'b1010; // Copy B: result = B (dùng cho LUI)

    // ===== FUNCTION3 =====
    localparam F3_ADD_SUB  = 3'b000;
    localparam F3_SLL      = 3'b001;
    localparam F3_SLT      = 3'b010;
    localparam F3_SLTU     = 3'b011;
    localparam F3_XOR      = 3'b100;
    localparam F3_SRL_SRA  = 3'b101;
    localparam F3_OR       = 3'b110;
    localparam F3_AND      = 3'b111;

    // ===== LOAD/STORE =====
    localparam F3_LB_SB  = 3'b000;
    localparam F3_LH_SH  = 3'b001;
    localparam F3_LW_SW  = 3'b010;
    localparam F3_LBU    = 3'b100;
    localparam F3_LHU    = 3'b101;

    // ===== BRANCH =====
    localparam F3_BEQ  = 3'b000;
    localparam F3_BNE  = 3'b001;
    localparam F3_BLT  = 3'b100;
    localparam F3_BGE  = 3'b101;
    localparam F3_BLTU = 3'b110;
    localparam F3_BGEU = 3'b111;

    // Internal decode
    logic [6:0] opcode;        // Lưu opcode của instruction
    logic [2:0] funct3;        // Lưu funct3 của instruction
    logic [6:0] funct7;        // Lưu funct7 của instruction
    logic pc_sel_branch;       // Tín hiệu quyết định branch có taken không

    assign opcode = i_inst[6:0];
    assign funct3 = i_inst[14:12];
    assign funct7 = i_inst[31:25];

    // ===== BRANCH DECODER =====
    always_comb begin
        case (funct3)
            F3_BEQ:  pc_sel_branch = i_br_equal;
            F3_BNE:  pc_sel_branch = ~i_br_equal;
            F3_BLT:  pc_sel_branch = i_br_less;
            F3_BGE:  pc_sel_branch = (~i_br_less) | i_br_equal;
            F3_BLTU: pc_sel_branch = i_br_less;
            F3_BGEU: pc_sel_branch = (~i_br_less) | i_br_equal;
            default: pc_sel_branch = 1'b0;
        endcase
    end

    // ===== MAIN CONTROL =====
    always_comb begin
        // defaults: prevents latches
        o_alu_op     = ALU_ADD;
        o_reg_wen    = 1'b0;
        o_alu_a_sel  = 1'b0;  //rs1
        o_alu_b_sel  = 1'b0;  //rs2
        o_imm_sel    = IMM_I;
        o_wb_sel     = 2'b00;  
        o_dmem_we    = 1'b0;
        o_pc_sel     = 1'b0;
        o_insn_vld   = 1'b0;
        o_br_un      = 1'b0;
        o_lsu_type   = 3'bxxx;

        case (opcode)
            // ---------------- R-TYPE ----------------
            OP_OP: begin
                o_reg_wen   = 1'b1;
                o_wb_sel    = 2'b01;
                o_insn_vld  = 1'b1;
                case (funct3)
                    F3_ADD_SUB: o_alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    F3_SLL:     o_alu_op = ALU_SLL;
                    F3_SLT:     o_alu_op = ALU_SLT;
                    F3_SLTU:    o_alu_op = ALU_SLTU;
                    F3_XOR:     o_alu_op = ALU_XOR;
                    F3_SRL_SRA: o_alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    F3_OR:      o_alu_op = ALU_OR;
                    F3_AND:     o_alu_op = ALU_AND;
                    default:    o_insn_vld = 1'b0; // Invalid funct3
                endcase
            end

            // ---------------- I-TYPE IMM ----------------
            OP_OP_IMM: begin
                o_reg_wen   = 1'b1;
                o_alu_b_sel = 1'b1; //IMM
                o_wb_sel    = 2'b01;
                o_insn_vld  = 1'b1;
                case (funct3)
                    F3_ADD_SUB: o_alu_op = ALU_ADD;
                    F3_SLL:     o_alu_op = ALU_SLL;
                    F3_SLT:     o_alu_op = ALU_SLT;
                    F3_SLTU:    o_alu_op = ALU_SLTU;
                    F3_XOR:     o_alu_op = ALU_XOR;
                    F3_SRL_SRA: o_alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    F3_OR:      o_alu_op = ALU_OR;
                    F3_AND:     o_alu_op = ALU_AND;
                    default:    o_insn_vld = 1'b0;
                endcase
            end

            // ---------------- LOAD ----------------
            OP_LOAD: begin
               o_reg_wen   = 1'b1;
                o_alu_b_sel = 1'b1;  //IMM
                o_imm_sel   = IMM_I;
                o_wb_sel    = 2'b00;
                o_alu_op    = ALU_ADD;
                o_insn_vld  = 1'b1;
                case (funct3)
                    F3_LW_SW:  o_lsu_type = 3'b000; // LW
                    F3_LB_SB:  o_lsu_type = 3'b001; // LB
                    F3_LBU:    o_lsu_type = 3'b010; // LBU
                    F3_LH_SH:  o_lsu_type = 3'b011; // LH
                    F3_LHU:    o_lsu_type = 3'b100; // LHU
                    default:   o_insn_vld = 1'b0;
                endcase
            end

            // ---------------- STORE ----------------
            OP_STORE: begin 	
                o_dmem_we   = 1'b1;
                o_alu_b_sel = 1'b1;  //IMM
                o_imm_sel   = IMM_S;
                o_alu_op    = ALU_ADD;
                o_insn_vld  = 1'b1;
		o_wb_sel     = 2'bxx; 
		o_br_un      = 1'bx;
                case (funct3)
                    F3_LW_SW: o_lsu_type = 3'b101;  //SW
                    F3_LB_SB: o_lsu_type = 3'b110;  //SB
                    F3_LH_SH: o_lsu_type = 3'b111;  //SH
                    default:  o_insn_vld = 1'b0;
                endcase
            end

            // ---------------- BRANCH ----------------
            OP_BRANCH: begin 
		o_lsu_type = 3'bxxx;
                o_alu_a_sel = 1'b1; // PC
                o_alu_b_sel = 1'b1;  // IMM
                o_imm_sel   = IMM_B;
                o_pc_sel    = pc_sel_branch;
                o_insn_vld  = 1'b1;
		o_wb_sel     = 2'bxx;
                // Set br_un for unsigned comparisons
                case (funct3)
                    F3_BEQ, F3_BNE, F3_BLT, F3_BGE: 
                        o_br_un = 1'b1; // Signed
                    F3_BLTU, F3_BGEU: 
                        o_br_un = 1'b0; // Unsigned
                    default: begin
                        o_br_un = 1'bx;
                        o_insn_vld = 1'b0;
                    end
                endcase
            end

            // ---------------- JAL ----------------
            OP_JAL: begin
                o_reg_wen   = 1'b1;
                o_alu_a_sel = 1'b1; // PC
                o_alu_b_sel = 1'b1;  // IMM
                o_imm_sel   = IMM_J;
                o_wb_sel    = 2'b10; // PC+4
                o_pc_sel    = 1'b1;
                o_insn_vld  = 1'b1;
            end

            // ---------------- JALR ----------------
            OP_JALR: begin
                o_reg_wen   = 1'b1;
                o_alu_a_sel = 1'b0; // rs1
                o_alu_b_sel = 1'b1;  // IMM
                o_imm_sel   = IMM_I;
                o_wb_sel    = 2'b10; // PC+4
                o_pc_sel    = 1'b1;
                // JALR must have funct3 = 0
                o_insn_vld  = (funct3 == 3'b000);
            end

            // ---------------- LUI ----------------
            OP_LUI: begin
                o_reg_wen   = 1'b1;
                o_alu_b_sel = 1'b1;  // IMM
                o_imm_sel   = IMM_U;
                o_alu_op    = ALU_COPY_B; // Pass imm to output
                o_wb_sel    = 2'b01; // ALU result
                o_insn_vld  = 1'b1;
            end

            // ---------------- AUIPC ----------------
            OP_AUIPC: begin
                o_reg_wen   = 1'b1;
                o_alu_a_sel = 1'b1; // PC
                o_alu_b_sel = 1'b1;  // IMM
                o_imm_sel   = IMM_U;
                o_alu_op    = ALU_ADD;
                o_wb_sel    = 2'b01; // ALU result
                o_insn_vld  = 1'b1;
            end

            // ---------------- INVALID ----------------
            default: begin
                // All signals already set to safe defaults
                o_insn_vld = 1'b0;
            end
        endcase
    end

endmodule