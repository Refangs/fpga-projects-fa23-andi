`include "opcode.vh"

module partial_load (
    input [31:0] mem_dout_raw,
    input [3:0] ld_mask,
    input sign,
    output reg [31:0] mem_dout
);
    // TODO: IMPLEMENT
    // 1111: lw
    // 1100: lh on upper half
    // 0011: lh on lower half
    // 1000, 0100, 0010, 0001: lb
    always @(*) begin
        mem_dout = 32'b0;
        case (ld_mask)
        4'b1111:
        begin
            mem_dout = mem_dout_raw;
        end
        4'b1100:
        begin
            mem_dout = {16{sign ? mem_dout_raw[31] : 1'b0}, mem_dout_raw[31:16]};
        end
        4'b0011:
        begin
            mem_dout = {16{sign ? mem_dout_raw[15] : 1'b0}, mem_dout_raw[15:0]};
        end
        4'b1000:
        begin
            mem_dout = {24{sign ? mem_dout_raw[31] : 1'b0}, mem_dout_raw[31:24]};
        end
        4'b0100:
        begin
            mem_dout = {24{sign ? mem_dout_raw[23] : 1'b0}, mem_dout_raw[23:16]};
        end
        4'b0010:
        begin
            mem_dout = {24{sign ? mem_dout_raw[15] : 1'b0}, mem_dout_raw[15:8]};
        end
        4'b0001:
        begin
            mem_dout = {24{sign ? mem_dout_raw[7] : 1'b0}, mem_dout_raw[7:0]};
        end
        endcase
    end
endmodule