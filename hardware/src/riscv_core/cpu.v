`include "opcode.vh"
`include "control_signals.vh"

module cpu #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input serial_in,
    output serial_out
);
    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] bios_addra, bios_addrb;
    wire [31:0] bios_douta, bios_doutb;
    wire bios_ena, bios_enb;
    bios_mem bios_mem (
      .clk(clk),
      .ena(bios_ena),
      .addra(bios_addra),
      .douta(bios_douta),
      .enb(bios_enb),
      .addrb(bios_addrb),
      .doutb(bios_doutb)
    );

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [13:0] dmem_addr;
    wire [31:0] dmem_din, dmem_dout;
    wire [3:0] dmem_we;
    wire dmem_en;
    dmem dmem (
      .clk(clk),
      .en(dmem_en),
      .we(dmem_we),
      .addr(dmem_addr),
      .din(dmem_din),
      .dout(dmem_dout)
    );

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [31:0] imem_dina, imem_doutb;
    wire [13:0] imem_addra, imem_addrb;
    wire [3:0] imem_wea;
    wire imem_ena;
    imem imem (
      .clk(clk),
      .ena(imem_ena),
      .wea(imem_wea),
      .addra(imem_addra),
      .dina(imem_dina),
      .addrb(imem_addrb),
      .doutb(imem_doutb)
    );

    // Register file
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    wire we;
    wire [4:0] ra1, ra2, wa;
    wire [31:0] wd;
    wire [31:0] rd1, rd2;
    reg_file rf (
        .clk(clk),
        .we(we),
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    // On-chip UART
    //// UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;
    //// UART Transmitter
    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;
    uart #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(rst),

        .serial_in(serial_in),
        .data_out(uart_rx_data_out),
        .data_out_valid(uart_rx_data_out_valid),
        .data_out_ready(uart_rx_data_out_ready),

        .serial_out(serial_out),
        .data_in(uart_tx_data_in),
        .data_in_valid(uart_tx_data_in_valid),
        .data_in_ready(uart_tx_data_in_ready)
    );

    // TODO: Your code to implement a fully functioning RISC-V core
    // Add as many modules as you want
    // Feel free to move the memory modules around

    wire [31:0] inst;

    reg [31:0] pc_ex;
    reg [31:0] inst_ex;

    wire [31:0] alu_out;
    wire pc_sel_ex;
    
    reg [31:0] alu_mem;
    reg [31:0] inst_mem;
    reg pc_sel_mem;

    reg pc_sel_mem_old; // new

    wire [31:0] mem_data_out;
    wire [31:0] data_resource_out;

    reg [31:0] cycle_cnt;
    

    /* Instruction Fetch/PC "Stage". */
    reg [31:0] pc;
    always @(posedge clk) begin
      if (rst) begin
        pc <= RESET_PC;
      end else begin
        // pc <= pc_sel_mem ? alu_mem : pc + 4;
        pc <= pc_sel_ex ? alu_out : pc + 4; // Predict branch not taken, flush if taken
        // Predict branch taken, flush if not taken
      end
    end

    /* Extra PCSel register to flush the third instruction for jumps and taken branches. */
    always @(posedge clk) begin
      if (rst) begin
        pc_sel_mem_old <= 0;
      end else begin
        pc_sel_mem_old <= pc_sel_mem;
      end
    end

    assign bios_addra = pc[13:2];
    assign imem_addrb = pc[15:2];


    /* ID stage pipeline registers. */
    reg [31:0] pc_id;
    always @(posedge clk) begin
      if (rst) begin
        pc_id <= RESET_PC;
      end else begin
        pc_id <= pc;
      end
    end

    /* ID to EX stage control (forwarding) logic. */
    // wire [31:0] inst;
    wire rd1_sel, rd2_sel;
    control_logic_id_ex cl_id_ex(
      .inst_id(inst),
      .inst_mem(inst_mem),
      .rd1_sel(rd1_sel),
      .rd2_sel(rd2_sel)
    );

    /* ID Stage. */
    wire [31:0] mem_inst_out;
    // wire [31:0] inst;
    assign mem_inst_out = pc_id[30] ? bios_douta : imem_doutb;
    assign inst = pc_sel_ex || pc_sel_mem ? 32'h00000013 : mem_inst_out;

    wire [31:0] imm;
    imm_gen imm_gen (
      .inst(inst),
      .imm(imm)
    );
    
    assign ra1 = inst[19:15];
    assign ra2 = inst[24:20];

    wire [31:0] rd1_fwd;
    wire [31:0] rd2_fwd;
    assign rd1_fwd = rd1_sel ? wd : rd1;
    assign rd2_fwd = rd2_sel ? wd : rd2;

    /* EX stage pipeline registers. */
    // reg [31:0] pc_ex;
    reg [31:0] rs1_ex;
    reg [31:0] rs2_ex;
    reg [31:0] imm_ex;
    // reg [31:0] inst_ex;
    always @(posedge clk) begin
      if (rst) begin
        pc_ex <= RESET_PC;
        rs1_ex <= 0;
        rs2_ex <= 0;
        imm_ex <= 0;
        inst_ex <= 32'h00000013;
      end else begin
        pc_ex <= pc_id;
        rs1_ex <= rd1_fwd;
        rs2_ex <= rd2_fwd;
        imm_ex <= imm;
        inst_ex <= inst;
      end
    end

    /* EX to MEM stage control logic. */
    wire breq, brlt, brun;
    wire [1:0] rs1_sel;
    wire [1:0] rs2_sel;
    wire a_sel;
    wire b_sel;
    wire [3:0] alu_sel;
    // wire [1:0] fwd_sel;
    //wire pc_sel_ex;
    control_logic_ex_mem cl_ex_mem(
      .inst_ex(inst_ex),
      .inst_mem(inst_mem),
      .breq(breq),
      .brlt(brlt),
      .brun(brun),
      .rs1_sel(rs1_sel),
      .rs2_sel(rs2_sel),
      .a_sel(a_sel),
      .b_sel(b_sel),
      .alu_sel(alu_sel),
      // .fwd_sel(fwd_sel),
      .pc_sel_ex(pc_sel_ex)
    );

    /* EX stage. */
    wire [31:0] rs1_ex_fwd;
    wire [31:0] rs2_ex_fwd;
    assign rs1_ex_fwd = rs1_sel == 0 ? rs1_ex : (rs1_sel == 1 ? alu_mem : data_resource_out);
    assign rs2_ex_fwd = rs2_sel == 0 ? rs2_ex : (rs2_sel == 1 ? alu_mem : data_resource_out);

    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;
    // fix pc addition in ALU? since top 4 bits are metadata. Maybe a problem
    assign alu_in_a = a_sel == 0 ? rs1_ex_fwd : pc_ex;
    assign alu_in_b = b_sel == 0 ? rs2_ex_fwd : imm_ex;

    //wire [31:0] alu_out;
    alu alu (
      .in_a(alu_in_a),
      .in_b(alu_in_b),
      .alu_sel(alu_sel),
      .alu_out(alu_out)
    );

    wire [31:0] mem_data_in_raw;
    assign mem_data_in_raw = rs2_ex_fwd;

    wire [3:0] mem_wmask;
    wire [31:0] mem_data_in;
    partial_store partial_store (
      .inst(inst_ex),
      .addr(alu_out),
      .data_in(mem_data_in_raw),
      .wmask(mem_wmask),
      .data_out(mem_data_in)
    );

    assign bios_addrb = alu_out[13:2];

    assign imem_addra = alu_out[15:2];
    assign imem_dina = mem_data_in;
    // assign imem_wea = (alu_out[31:29] == 3'b001 && pc_ex[30] == 1) ? mem_wmask : 4'b0000;
    assign imem_wea = (inst_ex[6:0] == `OPC_STORE && alu_out[31:29] == 3'b001 && pc_ex[30] == 1) ? mem_wmask : 4'b0;

    assign dmem_addr = alu_out[15:2];
    assign dmem_din = mem_data_in;
    // assign dmem_we = (alu_out[31:30] == 2'b00 && alu_out[28] == 1) ? mem_wmask : 4'b0000;
    assign dmem_we = (inst_ex[6:0] == `OPC_STORE && alu_out[31:30] == 2'b00 && alu_out[28] == 1) ?  mem_wmask : 4'b0;


    branch_comp branch_comp (
      .rs1(rs1_ex_fwd),
      .rs2(rs2_ex_fwd),
      .brun(brun),
      .breq(breq),
      .brlt(brlt)
    );

    assign uart_rx_data_out_ready = inst_ex[6:0] == `OPC_LOAD && alu_out == 32'h80000004;
    assign uart_tx_data_in_valid = inst_ex[6:0] == `OPC_STORE && alu_out == 32'h80000008;
    assign uart_tx_data_in = rs2_ex_fwd[7:0];

    /* MEM stage pipeline registers. */
    reg [31:0] pc_mem;
    //reg [31:0] alu_mem;
    //reg [31:0] inst_mem;
    //reg pc_sel_mem;
    always @(posedge clk) begin
      if (rst) begin
        pc_mem <= RESET_PC;
        alu_mem <= 0;
        inst_mem <= 32'h00000013;
        pc_sel_mem <= 0;
      end else begin
        pc_mem <= pc_ex;
        alu_mem <= alu_out;
        inst_mem <= inst_ex;
        pc_sel_mem <= pc_sel_ex;
      end
    end

    /* CSR register. */
    reg [31:0] tohost_csr;
    always @(posedge clk) begin
      if (rst) begin
        tohost_csr <= 0;
      end else begin
        if (inst_ex[6:0] == `OPC_CSR) begin
          if (inst_ex[14:12] == 3'b001) begin
            // csrrw
            tohost_csr <= rs1_ex_fwd;
          end else begin
            // csrrwi
            tohost_csr <= imm_ex;
          end
        end else begin
          tohost_csr <= tohost_csr;
        end
      end
    end
    

    /* Cycle Counter. */
    // reg [31:0] cycle_cnt;
    always @(posedge clk) begin
      if (rst) begin
        cycle_cnt <= 0;
      end else begin
        if (inst_ex[6:0] == `OPC_STORE && alu_out == 32'h80000018) begin
          cycle_cnt <= 0;
        end else begin
          cycle_cnt <= cycle_cnt + 1;
        end
      end
    end

    /* Instruction Counter. */
    reg [31:0] inst_cnt;
    always @(posedge clk) begin
      if (rst) begin
        inst_cnt <= 0;
      end else begin
        if (inst_ex[6:0] == `OPC_STORE && alu_out == 32'h80000018) begin
          inst_cnt <= 0;
        end else begin
          if (inst_mem == 32'h00000013) begin
            inst_cnt <= inst_cnt;
          end else begin
            inst_cnt <= inst_cnt + 1;
          end
        end
        // else if (cycle_cnt > 3 && inst_mem != 32'h00000013) begin
        //   // maybe don't hardcode later. Make pipeline registers to keep track of whether an instruction is valid
        //   inst_cnt <= inst_cnt + 1;
        // end else begin
        //   inst_cnt <= inst_cnt;
        // end
      end
    end

    /* MEM to PC stage control logic. */
    wire [3:0] ld_mask;
    wire ld_sign;
    wire [2:0] io_sel;
    wire [1:0] wb_sel;
    wire reg_wen;
    control_logic_mem_pc cl_mem_pc (
      .inst_mem(inst_mem),
      .alu_mem(alu_mem),
      .ld_mask(ld_mask),
      .ld_sign(ld_sign),
      .io_sel(io_sel),
      .wb_sel(wb_sel),
      .reg_wen(reg_wen)
    );

    /* MEM stage. */
    wire [31:0] mem_data_out_raw;
    assign mem_data_out_raw = alu_mem[30] ? bios_doutb : dmem_dout;

    //wire [31:0] mem_data_out;
    partial_load partial_load (
      .mem_dout_raw(mem_data_out_raw),
      .ld_mask(ld_mask),
      .sign(ld_sign),
      .mem_dout(mem_data_out)
    );

    wire [31:0] uart_control_out_32;
    wire [31:0] uart_rx_data_out_32;
    assign uart_control_out_32 = {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready};
    assign uart_rx_data_out_32 = {24'b0, uart_rx_data_out};

    //wire [31:0] data_resource_out;
    //assign data_resource_out = io_sel == 0 ? mem_data_out : (io_sel == 1 ? uart_control_out_32 : (io_sel == 2 ? uart_rx_data_out_32 : (io_sel == 3 ? cycle_cnt : io_sel == 4 ? inst_cnt : 0))); // add IO logic later (UART, cycle count, inst count)
    assign data_resource_out = io_sel == 0 ? mem_data_out : (io_sel == 1 ? uart_control_out_32 : (io_sel == 2 ? uart_rx_data_out_32 : (io_sel == 3 ? cycle_cnt : (io_sel == 4 ? inst_cnt : 0))));

    assign wd = wb_sel == 0 ? alu_mem : (wb_sel == 1 ? data_resource_out : pc_mem + 4);
    assign wa = inst_mem[11:7];
    assign we = reg_wen;


    // Fix later. Add to control logic?
    // assign dmem_en = 1;
    // assign imem_ena = 1;
    // assign bios_ena = 1;
    // assign bios_enb = 1;

    assign dmem_en = (inst_ex[6:0] == `OPC_STORE || inst_ex[6:0] == `OPC_LOAD) && alu_out[31:30] == 2'b0 && alu_out[28] == 1'b1;
    assign imem_ena = inst_ex[6:0] == `OPC_STORE && alu_out[31:29] == 3'b001 && pc_ex[30] == 1;
    assign bios_ena = pc[30] == 1;
    assign bios_enb = alu_out[30] == 1;
    
endmodule
