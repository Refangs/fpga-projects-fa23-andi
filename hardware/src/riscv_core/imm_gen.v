`include "opcode.vh"

module imm_gen (
    input [31:0] inst,
    // input [3:0] imm_sel,
    output reg [31:0] imm
);
    wire [6:0] opcode;
    wire [2:0] funct3;
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    always @(*) begin
        imm = 32'b0;
        case (opcode)
        `OPC_ARI_ITYPE, `OPC_LOAD, `OPC_JALR:
        begin
            // do I type (and I* type)
            if (funct3 == 3'b101) begin
                // I* type
                imm = {27'b0, inst[24:20]};
            end else begin
                // I type
                imm = {{20{inst[31]}}, inst[31:20]};
            end
        end
        `OPC_STORE:
        begin
            // S Type
            imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        end
        `OPC_BRANCH:
        begin
            // B type
            imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        end
        `OPC_LUI, `OPC_AUIPC:
        begin
            // U type
            imm = {inst[31:12], 12'b0};
        end
        `OPC_JAL:
        begin
            // J type
            imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
        end
        `OPC_CSR:
        begin
            // CSR type
            imm = {27'b0, inst[19:15]};
        end
        default:
        begin
            imm = 32'b0;
        end
        endcase
    end
endmodule
