// List of control signal values.

`ifndef CONTROL_SIGNALS
`define CONTROL_SIGNALS

/* ASel values */
`define ASEL_RS1        2'd0
`define ASEL_PC         2'd1
`define ASEL_ALU_FWD    2'd2
`define ASEL_MEM_FWD    2'd3

/* BSel values */
`define BSEL_RS2        2'd0
`define BSEL_IMM        2'd1
`define BSEL_ALU_FWD    2'd2
`define BSEL_MEM_FWD    2'd3

/* ALUSel values */
`define ALU_ADD     4'd0
`define ALU_SLL     4'd1
`define ALU_SLT     4'd2
`define ALU_SLTU    4'd3
`define ALU_XOR     4'd4
`define ALU_SRL     4'd5
`define ALU_OR      4'd6
`define ALU_AND     4'd7
`define ALU_SUB     4'd8
`define ALU_SRA     4'd9
`define ALU_BSEL    4'd10
// 11-15: Unused

/* FwdSel values (change to MemInSel? or DInSel) */
// TODO

/* PCSel values */
`define PCSEL_PLUS_4    1'b0
`define PCSEL_ALU       1'b1

/* IOSel values */
// TODO

/* WBSel values */
`define WBSEL_PC_PLUS_4 2'd2
`define WBSEL_DATA_OUT  2'd1
`define WBSEL_ALU_OUT   2'd0


`endif //ALU_OPS