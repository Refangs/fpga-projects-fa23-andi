module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);

// inputs: clk, rst, wr_en, rd_en, din
// outputs: full, empty, dout

    // number of items in the buffer
    reg [5:0] num_items;

    assign full = num_items == DEPTH;
    assign empty = num_items == 0;

    // 2D reg: There are 32 (DEPTH) regs of size 8 (WIDTH). buffer[0] is the 0-th register, buffer[1] is the 1st register, etc.
    reg [WIDTH-1:0] buffer [DEPTH-1:0];

    reg [POINTER_WIDTH-1:0] rd_ptr;
    reg [POINTER_WIDTH-1:0] wr_ptr;

    reg [WIDTH-1:0] dout_reg;
    assign dout = dout_reg;

    always @(posedge clk) begin
        if (rst) begin
            num_items <= 0;
            rd_ptr <= 0;
            wr_ptr <= 0;
        end else begin
            if (rd_en && num_items > 0) begin
                dout_reg = buffer[rd_ptr];
                rd_ptr = rd_ptr + 1;
                num_items = num_items - 1;
            end
            if (wr_en && num_items < DEPTH) begin
                buffer[wr_ptr] = din;
                wr_ptr = wr_ptr + 1;
                num_items = num_items + 1;
            end
        end
    end

    // SystemVerilog Assertions
    property full_no_write;
        @(posedge clk) wr_en && full |-> ##1 wr_ptr == $past(wr_ptr);
    endproperty
    assert property(full_no_write);

    property empty_no_read;
        @(posedge clk) rd_en && empty |-> ##1 rd_ptr == $past(rd_ptr);
    endproperty
    assert property(empty_no_read);

    property correct_reset;
        @(posedge clk) rst |-> ##1 (rd_ptr == 0) && (wr_ptr == 0) && (full == 0);
    endproperty
    assert property(correct_reset);

endmodule
