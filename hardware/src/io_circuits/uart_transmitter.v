module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

    wire symbol_edge;
    wire tx_running;
    wire start;

    reg [7:0] old_data;
    reg [3:0] bit_counter;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;
    reg serial_out_reg;

    assign serial_out = serial_out_reg;

    // symbol_edge is high whenever we want to send one bit
    assign symbol_edge = clock_counter == 1;
    // bit_counter == 0 means that we are idle
    assign tx_running = bit_counter != 4'd0;
    // we want to start running if we are currently not running and the input is valid
    assign start = data_in_valid && !tx_running;
    // we are ready if we are not running
    assign data_in_ready = !tx_running;

    always @(posedge clk) begin
        clock_counter <= (start || reset || clock_counter == (SYMBOL_EDGE_TIME - 1)) ? 0 : clock_counter + 1;
    end

    always @(posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
        end else if (start) begin
            bit_counter <= 11;
            old_data <= data_in;
        end else if (symbol_edge && tx_running) begin
            if (bit_counter == 11) begin
                // send 0 for the start bit
                serial_out_reg <= 0;
            end else if (bit_counter > 2) begin
                // if bit_counter is in [9, 2] send the corresponding data bit
                serial_out_reg <= old_data[10 - bit_counter];
            end else if (bit_counter == 2) begin
                // send 1 for the stop bit
                serial_out_reg <= 1;
            end
            bit_counter <= bit_counter - 1;
        end
        
        if (!tx_running) begin
            serial_out_reg <= 1;
        end
    end

// worked but timed out
    // always @(posedge clk) begin
    //     if (reset) begin
    //         bit_counter <= 0;
    //     end else if (start) begin
    //         bit_counter <= 10;
    //         old_data <= data_in;
    //     end else if (symbol_edge && tx_running) begin
    //         if (bit_counter == 10) begin
    //             // send 0 for the start bit
    //             serial_out_reg <= 0;
    //         end else if (bit_counter > 1) begin
    //             // if bit_counter is in [9, 2] send the corresponding data bit
    //             serial_out_reg <= old_data[9 - bit_counter];
    //         end else if (bit_counter == 1) begin
    //             // send 1 for the stop bit
    //             serial_out_reg <= 1;
    //         end
    //         bit_counter <= bit_counter - 1;
    //     end
        
    //     if (!tx_running) begin
    //         serial_out_reg <= 1;
    //     end
    // end



    // always @(posedge clk) begin
    //     if (symbol_edge) begin
    //         if (bit_counter == 10) begin
    //             // send 0 for the start bit
    //             serial_out_reg <= 0;
    //         end else if (bit_counter > 1) begin
    //             // if bit_counter is in [9, 2] send the corresponding data bit
    //             serial_out_reg <= data_in[9 - bit_counter];
    //         end else if (bit_counter == 1) begin
    //             // send 1 for the stop bit
    //             serial_out_reg <= 1;
    //         end else begin
    //             // send 1 if IDLE
    //             serial_out_reg <= 1;
    //         end
    //     end
    // end

    // always @(posedge clk) begin
    //     if (symbol_edge) begin
    //         if (bit_counter == 10) begin
    //             serial_out_reg <= 0;
    //         end else if (bit_counter > 1) begin
    //             serial_out_reg <= data_in[bit_counter - 1];
    //         end else if (bit_counter == 1) begin
    //             serial_out_reg <= 1;
    //         end 
    //         bit_counter <= bit_counter == 10 ? 0 : bit_counter + 1;
    //     end
    // end




endmodule
