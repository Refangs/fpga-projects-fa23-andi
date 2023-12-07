module sampler (
    input clk,
    input rst,
    input synth_valid,
    input [9:0] scaled_synth_code,
    output synth_ready,
    output pwm_out
);
    // Remove these lines once you have implemented this module

    reg [11:0] clock_counter;
    always @(posedge clk) begin
        if (rst) begin
            clock_counter <= 0;
        end else begin
            clock_counter <= clock_counter == 2499 ? 0 : clock_counter + 1;
        end
    end

    assign synth_ready = clock_counter == 2499;
    reg [9:0] valid_code;
    always @(posedge clk) begin
        if (rst) begin
            valid_code <= 0;
        end else begin
            valid_code <= synth_ready && synth_valid ? scaled_synth_code : valid_code;
        end
    end

    sigma_delta_dac dac(
        .clk(clk),
        .rst(rst),
        .code(valid_code),
        .pwm(pwm_out)
    );
    
endmodule