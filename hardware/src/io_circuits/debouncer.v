module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);
    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required, one saturating counter is needed for each bit of glitchy_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec

    // Synchronizer
    reg [WIDTH-1:0] sync_intermediate;
    reg [WIDTH-1:0] sync_out;
    always @(posedge clk) begin
	    sync_intermediate <= glitchy_signal;
	    sync_out <= sync_intermediate;
    end

    // Sample Pulse Generator + Saturating Counter
    reg [WRAPPING_CNT_WIDTH-1:0] sample_cnt;
    reg [SAT_CNT_WIDTH-1:0] pulse_cnt [WIDTH-1:0];

    integer i;
    always @(posedge clk) begin
	    if (sample_cnt == SAMPLE_CNT_MAX) begin
		    sample_cnt <= 1;
		    for (i = 0; i < WIDTH; i = i + 1) begin
			    if (sync_out[i] == 1'b1) begin
				    if (pulse_cnt[i] < PULSE_CNT_MAX) begin
					    pulse_cnt[i] <= pulse_cnt[i] + 1;
				    end
			    end else begin
				    pulse_cnt[i] <= 0;
			    end
		    end
	    end else begin
		    sample_cnt <= sample_cnt + 1;
	    end
    end

    genvar j;

    generate
	    for (j = 0; j < WIDTH; j = j + 1) begin
		    assign debounced_signal[j] = pulse_cnt[j] == PULSE_CNT_MAX ? 1'b1 : 1'b0;
	    end
    endgenerate

    integer x;
    initial begin
	    sync_intermediate = 0;
	    sync_out = 0;
	    sample_cnt = 0;
	    for (x = 0; x < WIDTH; x = x + 1) begin
		    pulse_cnt[i] = 0;
	    end
    end

endmodule
