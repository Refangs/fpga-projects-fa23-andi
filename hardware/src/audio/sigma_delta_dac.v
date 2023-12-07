module sigma_delta_dac #(
    parameter CODE_WIDTH = 10
)(
    input clk,
    input rst,
    input [CODE_WIDTH-1:0] code,
    output pwm
);
    reg [CODE_WIDTH:0] accumulator;
    reg [CODE_WIDTH:0] accumulator_old;
    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 0;
            accumulator_old <= 0;
        end else begin
            accumulator <= accumulator + code;
            accumulator_old <= accumulator;
        end
    end

    assign pwm = accumulator[10] ^ accumulator_old[10];
endmodule
