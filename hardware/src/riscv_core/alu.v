`include "control_signals.vh"

module alu (
    input [31:0] in_a,
    input [31:0] in_b,
    input [3:0] alu_sel,
    output reg [31:0] alu_out
);

    wire a_sign, b_sign;
    assign a_sign = in_a[31];
    assign b_sign = in_b[31];

    wire signed [31:0] a_signed;
    assign a_signed = in_a;

    always @(*) begin
        alu_out = 32'b0;
        case (alu_sel)
        `ALU_ADD:
            alu_out = in_a + in_b;
        `ALU_SLL:
            alu_out = in_a << in_b[4:0];
        `ALU_SLT:
        begin
            if (a_sign && b_sign) begin
                alu_out = in_a < in_b;
            end else if (a_sign && !b_sign) begin
                alu_out = 32'b1;
            end else if (!a_sign && b_sign) begin
                alu_out = 32'b0;
            end else begin
                alu_out = in_a < in_b;
            end
        end
        `ALU_SLTU:
            alu_out = in_a < in_b ? 32'b1 : 32'b0;
        `ALU_XOR:
            alu_out = in_a ^ in_b;
        `ALU_SRL:
            alu_out = in_a >> in_b[4:0];
        `ALU_OR:
            alu_out = in_a | in_b;
        `ALU_AND:
            alu_out = in_a & in_b;
        `ALU_SUB:
            alu_out = in_a - in_b;
        `ALU_SRA:
            alu_out = a_signed >>> in_b[4:0];
        `ALU_BSEL:
            alu_out = in_b;
        default:
            alu_out = 32'b0;
        endcase
    end


endmodule
