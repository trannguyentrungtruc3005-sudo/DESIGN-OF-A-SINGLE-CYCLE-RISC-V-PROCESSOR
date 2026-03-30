module single_cycle (

    input  logic        i_clk,

    input  logic        i_reset,

    input  logic [31:0] i_io_sw,

    output logic [31:0] o_pc_debug,

    output logic        o_insn_vld,

    output logic [31:0] o_io_ledr,

    output logic [31:0] o_io_ledg,

    output logic [31:0] o_io_lcd,

    output logic [31:0]  o_io_hex0,

    output logic [31:0]  o_io_hex1,

    output logic [31:0]  o_io_hex2,

    output logic [31:0]  o_io_hex3,

    output logic [31:0]  o_io_hex4,

    output logic [31:0]  o_io_hex5,

    output logic [31:0]  o_io_hex6,

    output logic [31:0]  o_io_hex7

);



    logic [31:0] pc, pc_next, pc_four;

    logic [31:0] instr;

    logic [3:0]  o_alu_op;

    logic        o_reg_wen;

    logic        o_alu_a_sel;

    logic        o_alu_b_sel;

    logic [2:0]  o_imm_sel;

    logic [1:0]  o_wb_sel;

    logic        o_dmem_we;

    logic        o_br_un;

    logic        o_pc_sel;

    logic [2:0]  o_lsu_type;

    logic        i_br_less;

    logic        i_br_equal;

    logic        cout_pc4;

    

    // Register File signals

    logic [31:0] rs1_data;

    logic [31:0] rs2_data;

    logic [31:0] wb_data;

    

    // Immediate value

    logic [31:0] imm;

    

    // ALU signals

    logic [31:0] alu_op_a;

    logic [31:0] alu_op_b;

    logic [31:0] alu_data;

    

    // LSU signals

    logic [31:0] ld_data;

    

    // Program Counter Logic

    add_sub add_pc4 (

        .x(pc),                  

        .y(32'd4),             

        .c_in(1'b0),           

        .s(pc_four),            

        .c_out(cout_pc4)        

    );



    // Next PC selection

    assign pc_next = (o_pc_sel == 1'b1) ? alu_data : pc_four;



    always_ff @(posedge i_clk or negedge i_reset) begin

        if (!i_reset)

            pc <= 32'h0000_0000;

        else

            pc <= pc_next;

    end



    

    // Debug output

    assign o_pc_debug = pc;

    

    // Instruction Memory    

    imem imem_inst (

        .i_reset(i_reset),

        .i_addr(pc),

        .o_rdata(instr)

    );

    

    

    control_unit ctrl (

        .i_inst(instr),

        .i_br_less(i_br_less),

        .i_br_equal(i_br_equal),

        .o_alu_op(o_alu_op),

        .o_reg_wen(o_reg_wen),

        .o_alu_a_sel(o_alu_a_sel),

        .o_alu_b_sel(o_alu_b_sel),

        .o_imm_sel(o_imm_sel),

        .o_wb_sel(o_wb_sel),

        .o_dmem_we(o_dmem_we),

        .o_br_un(o_br_un),

        .o_pc_sel(o_pc_sel),

        .o_insn_vld(o_insn_vld),

        .o_lsu_type(o_lsu_type)

    );



    // Register File   

    regfile regfile_inst (

        .i_clk(i_clk),

        .i_reset(i_reset),

        .i_rs1_addr(instr[19:15]),

        .i_rs2_addr(instr[24:20]),

        .i_rd_addr(instr[11:7]),

        .i_rd_data(wb_data),

        .i_rd_wren(o_reg_wen),

        .o_rs1_data(rs1_data),

        .o_rs2_data(rs2_data)

    );



    // Immediate Generator   

    imm_gen imm_gen_inst (

        .i_immsel(o_imm_sel),

        .i_inst(instr),

        .o_imm(imm)

    );

    

    // Branch Comparator Unit

    brc brc_inst (

        .i_rs1_data(rs1_data),

        .i_rs2_data(rs2_data),

        .i_br_un(o_br_un),

        .o_br_less(i_br_less),

        .o_br_equal(i_br_equal)

    );

    

    // ALU

    assign alu_op_a = (o_alu_a_sel) ? pc : rs1_data;

    assign alu_op_b = (o_alu_b_sel) ? imm : rs2_data;



    alu alu_inst (

        .i_op_a(alu_op_a),

        .i_op_b(alu_op_b),

        .i_alu_op(o_alu_op),

        .o_alu_data(alu_data)

    );

    

    // LSU

    lsu lsu_inst (

        .i_clk(i_clk),

        .i_reset(i_reset),

        .i_lsu_wren(o_dmem_we),

        .i_lsu_addr(alu_data),

        .i_st_data(rs2_data),

        .i_io_sw(i_io_sw),

        .i_type(o_lsu_type),

        .o_ld_data(ld_data),

        .o_io_ledr(o_io_ledr),

        .o_io_ledg(o_io_ledg),

        .o_io_lcd(o_io_lcd),

        .o_io_hex0(o_io_hex0[6:0]),

        .o_io_hex1(o_io_hex1[6:0]),

        .o_io_hex2(o_io_hex2[6:0]),

        .o_io_hex3(o_io_hex3[6:0]),

        .o_io_hex4(o_io_hex4[6:0]),

        .o_io_hex5(o_io_hex5[6:0]),

        .o_io_hex6(o_io_hex6[6:0]),

        .o_io_hex7(o_io_hex7[6:0])

    );



    assign o_io_hex0[31:7] = 25'b0;

    assign o_io_hex1[31:7] = 25'b0;

    assign o_io_hex2[31:7] = 25'b0;

    assign o_io_hex3[31:7] = 25'b0;

    assign o_io_hex4[31:7] = 25'b0;

    assign o_io_hex5[31:7] = 25'b0;

    assign o_io_hex6[31:7] = 25'b0;

    assign o_io_hex7[31:7] = 25'b0;



    // Write-Back Mux

    always_comb begin

        case (o_wb_sel)

            2'b00: wb_data = ld_data;    // Load data from memory

            2'b01: wb_data = alu_data;   // ALU result

            2'b10: wb_data = pc_four;    // PC + 4 (for JAL/JALR)

            default: wb_data = 32'd0;

        endcase

    end





endmodule : single_cycle



