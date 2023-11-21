module branch_comp (
    // change name of rs1 and rs2 maybe. can be confusing
    input [31:0] rs1,
    input [31:0] rs2,
    input brun,
    output breq,
    output reg brlt
);

    assign breq = rs1 == rs2;

    wire rs1_sign, rs2_sign;
    assign rs1_sign = rs1[31];
    assign rs2_sign = rs2[31];

    always @(*) begin
        if (!brun) begin
            if (rs1_sign && rs2_sign) begin
                brlt = rs1 > rs2;
            end else if (rs1_sign && !rs2_sign) begin
                brlt = 1'b1;
            end else if (!rs1_sign && rs2_sign) begin
                brlt = 1'b0;
            end else begin
                brlt = rs1 < rs2;
            end
        end else begin
            brlt = rs1 < rs2;
        end
    end
endmodule
