module cpu_to_synth_cdc #(
    parameter N_VOICES = 1
)(
    input cpu_clk,
    input [N_VOICES-1:0] [23:0] cpu_carrier_fcws,
    input [23:0] cpu_mod_fcw,
    input [4:0] cpu_mod_shift,
    input [N_VOICES-1:0] cpu_note_en,
    input [4:0] cpu_synth_shift,
    input cpu_req,
    output cpu_ack,

    input synth_clk,
    output [N_VOICES-1:0] [23:0] synth_carrier_fcws,
    output [23:0] synth_mod_fcw,
    output [4:0] synth_mod_shift,
    output [N_VOICES-1:0] synth_note_en,
    output [4:0] synth_synth_shift
);

    wire synth_req;
    synchronizer req_sync (
        .async_signal(cpu_req), 
        .clk(synth_clk), 
        .sync_signal(synth_req)
    );

    reg synth_req_reg;
    always @(posedge synth_clk) begin
        synth_req_reg <= synth_req;
    end

    synchronizer ack_sync (
        .async_signal(synth_req_reg), 
        .clk(cpu_clk), 
        .sync_signal(cpu_ack)
    );

    reg [N_VOICES-1:0] [23:0] synth_carrier_fcws_reg;
    reg [23:0] synth_mod_fcw_reg;
    reg [4:0] synth_mod_shift_reg;
    reg [N_VOICES-1:0] synth_note_en_reg;
    reg [4:0] synth_synth_shift_reg;

    assign synth_carrier_fcws = synth_carrier_fcws_reg;
    assign synth_mod_fcw = synth_mod_fcw_reg;
    assign synth_mod_shift = synth_mod_shift_reg;
    assign synth_note_en = synth_note_en_reg;
    assign synth_synth_shift = synth_synth_shift_reg; 

    always @(posedge synth_clk) begin
        if (synth_req_reg) begin
            synth_carrier_fcws_reg <= cpu_carrier_fcws;
            synth_mod_fcw_reg <= cpu_mod_fcw;
            synth_mod_shift_reg <= cpu_mod_shift;
            synth_note_en_reg <= cpu_note_en;
            synth_synth_shift_reg <= cpu_synth_shift;
        end else begin
            synth_carrier_fcws_reg <= synth_carrier_fcws_reg;
            synth_mod_fcw_reg <= synth_mod_fcw_reg;
            synth_mod_shift_reg <= synth_mod_shift_reg;
            synth_note_en_reg <= synth_note_en_reg;
            synth_synth_shift_reg <= synth_synth_shift_reg;
        end
    end

    // assign synth_carrier_fcws = synth_req ? cpu_carrier_fcws : 0;
    // assign synth_mod_fcw = synth_req ? cpu_mod_fcw : 0;
    // assign synth_mod_shift = synth_req ? cpu_mod_shift : 0;
    // assign synth_note_en = synth_req ? cpu_note_en : 0;
    // assign synth_synth_shift = synth_req ? cpu_synth_shift : 0;
endmodule