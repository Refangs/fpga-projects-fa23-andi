module nco(
    input clk,
    input rst,
    input [23:0] fcw,
    input next_sample,
    output [13:0] code
);

    wire [7:0] addr;
    wire [13:0] sine_lut_out;
    sine_lut sine_lut (
        .address(addr),
        .data(sine_lut_out)
    );

    

    assign code = sine_lut_out;
    reg [23:0] pa; // phase accumulator

    assign addr = pa[23:16];

    always @(posedge clk) begin
        if (rst) begin
            pa <= 0;
        end else begin
            if (next_sample == 1) begin
                pa <= pa + fcw;
            end
        end
    end
    
endmodule
