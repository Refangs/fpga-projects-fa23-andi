`include "opcode.vh"

module control_logic_mem_pc (
    input [31:0] inst_mem,
    input [31:0] alu_mem,
    output reg [3:0] ld_mask,
    output reg ld_sign,
    output reg [1:0] io_sel,
    output reg [1:0] wb_sel,
    output reg_wen
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [1:0] offset;
    assign opcode = inst_mem[6:0];
    assign funct3 = inst_mem[14:12];
    assign offset = alu_mem[1:0];
    
    /* LdMask, LdSign */
    always @(*) begin
        ld_mask = 4'b0;
        ld_sign = 1'b1;
        if (opcode == `OPC_LOAD) begin
            case (funct3)
            `FNC_LB:
            begin
                ld_mask = 4'b1 << offset;
                ld_sign = 1'b1;
            end
            `FNC_LH:
            begin
                ld_mask = 4'b11 << offset;
                ld_sign = 1'b1;
            end
            `FNC_LW:
            begin
                ld_mask = 4'b1111;
                ld_sign = 1'b1;
            end
            `FNC_LBU:
            begin
                ld_mask = 4'b1 << offset;
                ld_sign = 1'b0;
            end
            `FNC_LHU:
            begin
                ld_mask = 4'b11 << offset;
                ld_sign = 1'b0;
            end
            default:
            begin
                ld_mask = 4'b0;
                ld_sign = 1'b1;
            end
            endcase
        end
    end

    // io_sel
    /*
    0: regular load
    1: UART load
    2: cycle count
    3: inst count
    */
    always @(*) begin
        io_sel = 2'b0;
        // implement later
    end

    /* WBSel */
    always @(*) begin
        if (opcode == `OPC_JAL || opcode == `OPC_JALR) begin
            wb_sel = `WBSEL_PC_PLUS_4;
        end else if (opcode == `OPC_LOAD) begin
            wb_sel = `WBSEL_DATA_OUT;
        end else begin
            wb_sel = `WBSEL_ALU_OUT;
        end
    end

    /* RegWEn */
    assign reg_wen = !(opcode == `OPC_STORE || opcode == `OPC_BRANCH);
endmodule