module z1top #(
    parameter BAUD_RATE = 115_200,
    // Warning: CPU_CLOCK_FREQ must match the PLL parameters!
    parameter CPU_CLOCK_FREQ = 50_000_000,
    // PLL Parameters: sets the CPU clock = 125Mhz * 34 / 5 / 17 = 50 MHz
    parameter CPU_CLK_CLKFBOUT_MULT = 34,
    parameter CPU_CLK_DIVCLK_DIVIDE = 5,
    parameter CPU_CLK_CLKOUT_DIVIDE  = 17,
    /* verilator lint_off REALCVT */
    // Sample the button signal every 500us
    parameter integer B_SAMPLE_CNT_MAX = 0.0005 * CPU_CLOCK_FREQ,
    // The button is considered 'pressed' after 100ms of continuous pressing
    parameter integer B_PULSE_CNT_MAX = 0.100 / 0.0005,
    /* lint_on */
    // The PC the RISC-V CPU should start at after reset
    parameter RESET_PC = 32'h4000_0000,
    parameter N_VOICES = 1
) (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS,
    input  FPGA_SERIAL_RX,
    output FPGA_SERIAL_TX,
    output AUD_PWM,
    output AUD_SD
);
    // Clocks and PLL lock status
    wire cpu_clk, cpu_clk_locked, pwm_clk, pwm_clk_locked;

    // Buttons after the button_parser
    wire [3:0] buttons_pressed;

    // Reset the CPU and all components on the cpu_clk if the reset button is
    // pushed or whenever the CPU clock PLL isn't locked
    wire cpu_reset;
    assign cpu_reset = buttons_pressed[0] || !cpu_clk_locked;

    // Use IOBs to drive/sense the UART serial lines
    wire cpu_tx, cpu_rx;
    (* IOB = "true" *) reg fpga_serial_tx_iob;
    (* IOB = "true" *) reg fpga_serial_rx_iob;
    assign FPGA_SERIAL_TX = fpga_serial_tx_iob;
    assign cpu_rx = fpga_serial_rx_iob;
    always @(posedge cpu_clk) begin
        fpga_serial_tx_iob <= cpu_tx;
        fpga_serial_rx_iob <= FPGA_SERIAL_RX;
    end

    // Use IOBs to drive the PWM output
    (* IOB = "true" *) reg pwm_iob;
    wire pwm_out; // TODO: connect this wire to your DAC
    assign AUD_PWM = pwm_iob;
    assign AUD_SD = 1'b1;
    always @(posedge pwm_clk) begin
        pwm_iob <= pwm_out;
    end

    // Generate a reset for the PWM clock domain
    wire pwm_rst, reset_button_pwm_domain;
    synchronizer rst_pwm_sync (.async_signal(buttons_pressed[0]), .sync_signal(reset_button_pwm_domain), .clk(pwm_clk));
    assign pwm_rst = reset_button_pwm_domain || ~pwm_clk_locked;

      
    clocks #(
        .CPU_CLK_CLKFBOUT_MULT(CPU_CLK_CLKFBOUT_MULT),
        .CPU_CLK_DIVCLK_DIVIDE(CPU_CLK_DIVCLK_DIVIDE),
        .CPU_CLK_CLKOUT_DIVIDE(CPU_CLK_CLKOUT_DIVIDE)
    ) clk_gen (
        .clk_125mhz(CLK_125MHZ_FPGA),
        .cpu_clk(cpu_clk),
        .cpu_clk_locked(cpu_clk_locked),
        .pwm_clk(pwm_clk),
        .pwm_clk_locked(pwm_clk_locked)
    );

    button_parser #(
        .WIDTH(4),
        .SAMPLE_CNT_MAX(B_SAMPLE_CNT_MAX),
        .PULSE_CNT_MAX(B_PULSE_CNT_MAX)
    ) bp (
        .clk(cpu_clk),
        .in(BUTTONS),
        .out(buttons_pressed)
    );

    wire fifo_empty;
    wire fifo_rd_en;
    wire [3:0] fifo_dout;

    fifo #(
        .WIDTH(4),
        .DEPTH(8)
    ) fifo (
        .clk(cpu_clk),
        .rst(cpu_reset),
        .wr_en(buttons_pressed > 0),
        .din(buttons_pressed),
        .full(),
        .rd_en(fifo_rd_en),
        .dout(fifo_dout),
        .empty(fifo_empty)
    );

    wire [N_VOICES-1:0] [23:0] cpu_carrier_fcws;
    wire [23:0] cpu_mod_fcw;
    wire [4:0] cpu_mod_shift;
    wire [N_VOICES-1:0] cpu_note_en;
    wire [4:0] cpu_synth_shift;
    wire cpu_req;
    
    wire cpu_ack;
    wire [N_VOICES-1:0] [23:0] synth_carrier_fcws;
    wire [23:0] synth_mod_fcw;
    wire [4:0] synth_mod_shift;
    wire [N_VOICES-1:0] synth_note_en;
    wire [4:0] synth_synth_shift;

    cpu #(
        .CPU_CLOCK_FREQ(CPU_CLOCK_FREQ),
        .RESET_PC(RESET_PC),
        .BAUD_RATE(BAUD_RATE)
    ) cpu (
        .clk(cpu_clk),
        .rst(cpu_reset),
        .fifo_empty(fifo_empty),
        .fifo_dout(fifo_dout),
        .fifo_rd_en(fifo_rd_en),
        .switches(SWITCHES),
        .leds(LEDS),
        .serial_out(cpu_tx),
        .serial_in(cpu_rx),
        .carrier_fcws(cpu_carrier_fcws),
        .mod_fcw(cpu_mod_fcw),
        .mod_shift(cpu_mod_shift),
        .note_en(cpu_note_en),
        .synth_shift(cpu_synth_shift),
        .req(cpu_req),
        .ack(cpu_ack)
    );

    cpu_to_synth_cdc #(
        .N_VOICES(N_VOICES)
    ) cdc (
        .cpu_clk(cpu_clk),
        .synth_clk(pwm_clk),
        .cpu_carrier_fcws(cpu_carrier_fcws),
        .cpu_mod_fcw(cpu_mod_fcw),
        .cpu_mod_shift(cpu_mod_shift),
        .cpu_note_en(cpu_note_en),
        .cpu_synth_shift(cpu_synth_shift),
        .cpu_req(cpu_req),
        .cpu_ack(cpu_ack),

        .synth_carrier_fcws(synth_carrier_fcws),
        .synth_mod_fcw(synth_mod_fcw),
        .synth_mod_shift(synth_mod_shift),
        .synth_note_en(synth_note_en),
        .synth_synth_shift(synth_synth_shift)
    );

    // TODO ? (below, fill in inputs/outputs)

    wire [13:0] sample;
    wire sample_valid, sample_ready;
    wire [9:0] scaled_sample;
    synth #(
        .N_VOICES(N_VOICES)
    ) synth (
        .clk(pwm_clk),
        .rst(pwm_rst),
        .carrier_fcws(synth_carrier_fcws),
        .mod_fcw(synth_mod_fcw),
        .mod_shift(synth_mod_shift),
        .note_en(synth_note_en),
        .sample(sample),
        .sample_valid(sample_valid),
        .sample_ready(sample_ready)
    );

    scaler scaler (
        .clk(pwm_clk),
        .synth_shift(5'b0),
        .synth_out(sample),
        .code(scaled_sample)
    );

    sampler sampler (
        .clk(pwm_clk),
        .rst(pwm_rst),
        .synth_valid(sample_valid),
        .synth_ready(sample_ready),
        .scaled_synth_code(scaled_sample),
        .pwm_out(pwm_out)
    );
    
endmodule
