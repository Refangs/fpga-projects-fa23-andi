`include "opcode.vh"
`include "control_signals.vh"

module control_logic_ex_mem (
    input [31:0] inst_ex,
    input [31:0] inst_mem,
    input breq,
    input brlt,
    output brun,
    output reg [1:0] rs1_sel,
    output reg [1:0] rs2_sel,
    output reg a_sel,
    output reg b_sel,
    output reg [3:0] alu_sel,
    output reg [1:0] fwd_sel,
    output pc_sel_ex
);
    
    wire [6:0] opcode_ex;
    wire [2:0] funct3_ex;
    wire [6:0] funct7_ex;
    wire [4:0] rs1_ex;
    wire [4:0] rs2_ex;
    assign opcode_ex = inst_ex[6:0];
    assign funct3_ex = inst_ex[14:12];
    assign funct7_ex = inst_ex[31:25];
    assign rs1_ex = inst_ex[19:15];
    assign rs2_ex = inst_ex[24:20];

    wire [6:0] opcode_mem;
    wire [2:0] funct3_mem;
    wire [6:0] funct7_mem;
    wire [4:0] rd_mem;
    assign opcode_mem = inst_mem[6:0];
    assign funct3_mem = inst_mem[14:12];
    assign funct7_mem = inst_mem[31:25];
    assign rd_mem = inst_mem[11:7];

    /* BrUn */
    assign brun = opcode_ex == `OPC_BRANCH && (funct3_ex == `FNC_BLTU || funct3_ex == `FNC_BGEU);

    /* RS1Sel, RS2Sel */
    wire has_rd_mem;    // true if inst_mem writes to rd
    wire uses_rs1_ex;   // true if inst_ex uses rs1 (either in alu or branch comp)
    wire uses_rs2_ex;   // true if inst_ex uses rs2 (either in alu or branch comp)

    // All instructions write to rd except for store, branch, and csrrwi (csrrw does but we can ignore since rd is always x0)
    assign has_rd_mem = !(opcode_mem == `OPC_STORE || opcode_mem == `OPC_BRANCH || opcode_mem == `OPC_CSR);

    // maybe don't even need uses_rs1_ex?? can always forward if rd_mem == rsx_ex (and rsx_ex is not x0). It will be filtered out by a_sel/b_sel if an instruction doesn't use it anyways

    // All instructions use rs1 (either in ALU or BC) except lui, auipc, jal, and csrrwi (can ignore csrrwi since it doesn't use alu. connect to csr reg later)
    assign uses_rs1_ex = !(opcode_ex == `OPC_LUI || opcode_ex == `OPC_AUIPC || opcode_ex == `OPC_JAL);

    // The only instructions that use rs2 are R-Types, store, and branch.
    assign uses_rs2_ex = opcode_ex == `OPC_ARI_RTYPE || opcode_ex == `OPC_STORE || opcode_ex == `OPC_BRANCH;

    /*
    0: rs1_ex or rs2_ex
    1: alu (mem stage)
    2: mem
    */

    // rs1
    always @(*) begin
        rs1_sel = 2'd0;
        if (has_rd_mem && uses_rs1_ex && rd_mem == rs1_ex && rs1_ex != 5'b0) begin
            if (opcode_mem == `OPC_LOAD) begin
                rs1_sel = 2'd2;
            end else begin
                rs1_sel = 2'd1;
            end
        end else begin
            rs1_sel = 2'd0;
        end
    end

    // rs2
    always @(*) begin
        rs2_sel = 2'd0;
        if (has_rd_mem && uses_rs2_ex && rd_mem == rs2_ex && rs2_ex != 5'b0) begin
            if (opcode_mem == `OPC_LOAD) begin
                rs2_sel = 2'd2;
            end else begin
                rs2_sel = 2'd1;
            end
        end else begin
            rs2_sel = 2'd0;
        end
    end

    // // NOTE: Need another forwarding path between mem/alu and branch comp? if we keep it in EX stage.
    // // We can also guarantee correct branch prediction by moving branch comp to ID stage
    // // ASel + BSel

    // // TODO!!!!!!!!!: Define localparams for what each selector means? maybe want global params actually.
    // // DEFINITELY ADD PARAMS for ALU (there are too many vals and don't want this to not work if alu operations are rearranged)
    // wire has_rd_mem;
    // wire uses_rs1_ex;
    // wire uses_rs2_ex;
    // // All instructions write to rd except for store, branch, and csrrwi (csrrw does but we can ignore since it's always rd)
    // assign has_rd_mem = !(opcode_mem == `OPC_STORE || opcode_mem == `OPC_BRANCH || opcode_mem == `OPC_CSR);
    // // All instructions use rs1 in the ALU except for jal, lui, auipc, and branch (branch uses in branch comp)
    // assign uses_rs1_ex = !(opcode_ex == `OPC_JAL || opcode_ex == `OPC_LUI || opcode_ex == `OPC_AUIPC || opcode_ex == `OPC_BRANCH);
    // // The only instructions that use rs2 in the ALU are R-type instructions (store rs2 goes to dmem input. branch rs2 goes to branch comp.)
    // assign uses_rs2_ex = opcode_ex == `OPC_ARI_RTYPE;




    // TODO: fix forwarding logic for A_sel and B_sel (they not working)





    // always @(*) begin
    //     a_sel = 2'd0;
    //     // need this if we have a jump in mem stage and a valid inst in ex stage
    //     // Add mux between PC and instruction memories (BIOS Mem + IMEM).
    //     // First input to mux is PC. Second input is PC in ID stage + offset from jal/jalr
    //     // if ((opcode_mem == OPC_JAL || opcode_mem == OPC_JALR) && rd_mem == rs1_ex) begin
    //     //     // Forward PC + 4 from mem stage (jal/jalr)
    //     //     a_sel = 3'd4;
    //     // end 
    //     if (uses_rs1_ex && has_rd_mem && rd_mem == rs1_ex) begin
    //         // If inst in EX stage uses rs1 and inst in MEM stage writes to rd, and rs1 == rd, want to forward
    //         if (opcode_mem == `OPC_LOAD) begin
    //             // Forward mem_dout (load)
    //             a_sel = 2'd3;
    //         end else begin
    //             // Forward alu_out (other instructions that write to rd)
    //             a_sel = 2'd2;
    //         end
    //     end else begin
    //         if (opcode_ex == `OPC_BRANCH || opcode_ex == `OPC_JAL || opcode_ex == `OPC_JALR || opcode_ex == `OPC_AUIPC) begin
    //             // Select PC for input a to ALU
    //             a_sel = 2'd1;
    //         end else begin
    //             // Select rs1 for input a to ALU
    //             a_sel = 2'd0;
    //         end
    //     end 
    // end

    always @(*) begin
        if (opcode_ex == `OPC_BRANCH || opcode_ex == `OPC_JAL || opcode_ex == `OPC_AUIPC) begin
            // JALR takes rs1 + imm
            a_sel = 1;
        end else begin
            a_sel = 0;
        end
    end


    //assign a_sel = 0;

    // BSel

    // always @(*) begin
    //     b_sel = 2'd0;
    //     if (uses_rs2_ex && has_rd_mem && rd_mem == rs2_ex) begin
    //         // If inst in EX stage uses rs2 and inst in MEM stage writes to rd, and rs2 == rd, want to forward
    //         if (opcode_mem == `OPC_LOAD) begin
    //             // Forward mem_dout (load)
    //             b_sel = 2'd3;
    //         end else begin
    //             // Forward alu_out (other instructions that write to rd)
    //             b_sel = 2'd2;
    //         end
    //     end else begin
    //         if (opcode_ex == `OPC_ARI_RTYPE) begin
    //             // Select rs2 for input b to ALU
    //             b_sel = 2'd0;
    //         end else begin
    //             // Select imm for input b to ALU
    //             b_sel = 2'd1;
    //         end
    //     end
    // end
    
    //assign b_sel = 0;

    always @(*) begin
        b_sel = opcode_ex == `OPC_ARI_RTYPE ? 0 : 1;
    end



    /* ALUSel */
    always @(*) begin
        alu_sel = 4'd0;
        if (opcode_ex == `OPC_ARI_RTYPE || opcode_ex == `OPC_ARI_ITYPE) begin
            case (funct3_ex)
            `FNC_ADD_SUB:
                alu_sel = opcode_ex == `OPC_ARI_RTYPE && funct7_ex == `FNC7_1 ? `ALU_SUB : `ALU_ADD;
            `FNC_SLL:
                alu_sel = `ALU_SLL;
            `FNC_SLT:
                alu_sel = `ALU_SLT;
            `FNC_SLTU:
                alu_sel = `ALU_SLTU;
            `FNC_XOR:
                alu_sel = `ALU_XOR;
            `FNC_OR:
                alu_sel = `ALU_OR;
            `FNC_AND:
                alu_sel = `ALU_AND;
            `FNC_SRL_SRA:
                alu_sel = funct7_ex == `FNC7_0 ? `ALU_SRL : `ALU_SRA;
            default:
                alu_sel = 4'd0;
            endcase
        end else if (opcode_ex == `OPC_LUI) begin
            alu_sel = `ALU_BSEL;
        end else begin
            alu_sel = `ALU_ADD;
        end
    end

    // TODO: fwd_sel
        // forward either mem or alu to input to data memories. (if not forwarding use rs2)

    /*
    0: rs2
    1: alu from mem stage
    2: mem (from mem stage)
    */
    always @(*) begin
        fwd_sel = 2'd0;
        if (opcode_ex == `OPC_STORE) begin
            // if store instruction is in EX, might need to forward something from MEM to write to memory
            if (has_rd_mem && rd_mem == rs2_ex) begin
                // if mem writes to rd and it's the same register as rs2 (which is data that goes into data memories)
                if (opcode_mem == `OPC_LOAD) begin
                    // if inst writing to rd in MEM stage is a load, need to forward memory
                    fwd_sel = 2'd2;
                end else begin
                    // other instructions that write to rd need to forward alu output (from mem)
                    fwd_sel = 2'd1;
                end
            end else begin
                fwd_sel = 2'd0;
            end
        end
    end

    // TODO: pc_sel_ex
        // if jal/jalr or taken branch

    wire beq_taken;
    wire bne_taken;
    wire blt_taken;
    wire bge_taken;
    wire taken_branch;
    assign beq_taken = funct3_ex == `FNC_BEQ && breq;
    assign bne_taken = funct3_ex == `FNC_BNE && !breq;
    // brlt is computed based on brun which is sent out
    assign blt_taken = (funct3_ex == `FNC_BLT || funct3_ex == `FNC_BLTU) && brlt;
    assign bge_taken = (funct3_ex == `FNC_BGE || funct3_ex == `FNC_BGEU) && !brlt;
    assign taken_branch = opcode_ex == `OPC_BRANCH && (beq_taken || bne_taken || blt_taken || bge_taken);
    assign pc_sel_ex = opcode_ex == `OPC_JAL || opcode_ex == `OPC_JALR || taken_branch;

endmodule