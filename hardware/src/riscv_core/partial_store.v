`include "opcode.vh"

module partial_store (
    input [31:0] inst,
    input [31:0] addr,
    input [31:0] data_in,
    output reg [3:0] wmask,
    output reg [31:0] data_out
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [1:0] offset;
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign offset = addr[1:0];

    always @(*) begin
        if (opcode != `OPC_STORE) begin
            wmask = 4'b0;
            data_out = 32'b0;
        end else begin
            // can probably simplify this code (take out assignment to data_out and maybe shifting wmask by offset?)
            case (funct3)
            `FNC_SW:
            begin
                wmask = 4'b1111;
                data_out = data_in;
            end
            `FNC_SH:
            begin
                wmask = 4'b0011 << offset;
                data_out = data_in << offset * 8;
            end
            `FNC_SB:
            begin
                wmask = 4'b0001 << offset;
                data_out = data_in << offset * 8;
            end
            default:
            begin
                wmask = 4'b0;
                data_out = 32'b0;
            end
            endcase
        end
    end


endmodule