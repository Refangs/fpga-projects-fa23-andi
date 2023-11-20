module alu (
    input [31:0] in_a,
    input [31:0] in_b,
    input [3:0] alu_sel,
    output reg [31:0] alu_out
);
    /*
    alu_sel values:

    0: add
    1: sll
    2: slt
    3: sltu
    4: xor
    5: srl
    6: or
    7: and
    8: sub
    9: sra
    10: bsel
    11: Unused
    12: Unused
    13: Unused
    14: Unused
    15: Unused

    */

    wire a_sign, b_sign;
    assign a_sign = in_a[31];
    assign b_sign = in_b[31];

    always @(*) begin
        alu_out = 32'b0;
        case (alu_sel)
        4'd0:
        begin
            // add
            alu_out = in_a + in_b;
        end
        4'd1:
        begin
            // shift left logical
            alu_out = in_a << in_b[4:0];
        end
        4'd2:
        begin
            // set less than
            alu_out = in_a < in_b ? 32'b0 : 32'b1;
        end
        4'd3:
        begin
            // set less than unsigned
            if (a_sign && b_sign) begin
                alu_out = in_a > in_b;
            end else if (a_sign && !b_sign) begin
                alu_out = 32'b1;
            end else if (!a_sign && b_sign) begin
                alu_out = 32'b0;
            end else begin
                alu_out = in_a < in_b;
            end
        end
        4'd4:
        begin
            // xor
            alu_out = in_a ^ in_b;
        end
        4'd5:
        begin
            // shift right logical
            alu_out = in_a >> in_b[4:0];
        end
        4'd6:
        begin
            // or
            alu_out = in_a | in_b;
        end
        4'd7:
        begin
            // and
            alu_out = in_a & in_b;
        end
        4'd8:
        begin
            // sub
            alu_out = in_a - in_b;
        end
        4'd9:
        begin
            // sra
            alu_out = in_a <<< in_b[4:0];
        end
        4'd10:
        begin
            // bsel
            alu_out = in_b;
        end
        4'd11:
        begin
            // unused
            alu_out = 32'b0;
        end
        4'd12:
        begin
            // unused
            alu_out = 32'b0;
        end
        4'd13:
        begin
            // unused
            alu_out = 32'b0;
        end
        4'd14:
        begin
            // unused
            alu_out = 32'b0;
        end
        4'd15:
        begin
            // unused
            alu_out = 32'b0;
        end
        endcase
    end


endmodule
