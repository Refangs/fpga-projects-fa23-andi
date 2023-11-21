module control_logic_id_ex (
    input [31:0] inst_id,
    input [31:0] inst_mem,
    output rd1_sel,
    output rd2_sel
);

    wire [6:0] opcode_id;
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    assign opcode_id = inst_id[6:0];
    assign rs1_id = inst_id[19:15];
    assign rs2_id = inst_id[24:20];

    wire [6:0] opcode_mem;
    wire [4:0] rd_mem;
    assign opcode_mem = inst_mem[6:0];
    assign rd_mem = inst_mem[11:7];

    wire has_rd_mem;    // true if inst_mem writes to rd
    assign has_rd_mem = !(opcode_mem == `OPC_STORE || opcode_mem == `OPC_BRANCH || opcode_mem == `OPC_CSR);

    /*
    rdx_sel
    0: output from RegFile
    1: forwarded output from write back
    */

    assign rd1_sel = has_rd_mem && rd_mem == rs1_id && rs1_id != 5'b0;
    assign rd2_sel = has_rd_mem && rd_mem == rs2_id && rs2_id != 5'b0;

endmodule