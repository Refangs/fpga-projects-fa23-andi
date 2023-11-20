module branch_comp (
    input [31:0] rs1,
    input [31:0] rs2,
    input brun,
    output reg breq,
    output reg brlt
);
    wire rs1_sign, rs2_sign;
    assign rs1_sign = rs1[31];
    assign rs2_sign = rs2[31];
    // TODO: IMPLEMENT
    always @(*) begin
        breq = rs1 == rs2;
        brlt = 1'b0;
        if (brun) begin
            if (rs1_sign && rs2_sign) begin
                // both sign bits are 1
                brlt = rs1 > rs2;
            end else if (rs1_sign && !rs2_sign) begin
                // rs1 sign bit is 1, rs2 sign bit is 0
                brlt = 1'b1;
            end else if (!rs1_sign && rs2_sign) begin
                // rs1 sign bit is 0, rs2 sign bit is 1
                brlt = 1'b0;
            end else begin
                // both sign bits are 0
                brlt = rs1 < rs2;
            end
        end else begin
            brlt = rs1 < rs2;
        end
    end
endmodule
