# Checkpoint 1 Questions
#### 1. How many stages is the datapath you've drawn?
3

#### 2. How do you handle ALU --> ALU hazards?
The ALU value computed for the instruction in stage 3 is forwarded to the ALU (as an input to the ASel and BSel muxes) for the instruction in stage 2.

#### 3. How do you handle ALU --> MEM hazards?
The ALU value computed for the instruction in stage 3 is forwarded to the data input to IMEM and DMEM for the instruction in stage 2, if the written value is used as data to be written (rs2). If the written value is used as an address, the forwarding path from the stage 3 ALU value (ALU_MEM) back to the ALU in stage 2 (through the muxes) takes care of it.

#### 4. How do you handle MEM --> ALU hazards?
The mem value gotten from memory for the instruction in stage 3 is forwarded to the ALU (as an input to the ASel and BSel muxes) for the instruction in stage 2.

#### 5. How do you handle MEM --> MEM hazards?
When a loaded value is written as data, the forwarding path from the mem value in stage 3 to the input of IMEM and DMEM handles it. WHen a loaded value is used as an address, the forwarding path from the mem value in stage 3 to the input of the ALU (through the muxes) in stage 2 handles it.

#### 6. Do you need special handling for 2 cycle apart hazards?
No. The RegFile is written at the end of stage 3, and read in the middle of stage 2. So instructions that are 1 instruction apart cannot affect each other as the earlier instruction will write at the beginning of the cycle that the later instruction is reading.

#### 7. How do you handle branch control hazards?
When a branch reaches stage 3, if it is taken, then the two instructions currently in stage 1 and 2 are turned into nops when they reach stage 3 (using a mux that feeds into INST_MEM). Branches are always predicted to be not taken. Mispredict latency is two cycles due to the two nops. No data hazards for taken branches since mispredict latency is two cycles.

#### 8. How do you handle jump control hazards? Consider jal and jalr separately. What optimizations can be made to special-case handle jal?
Jump control hazards are handled the same way as branches (stage 1 and 2 are flushed if PCSel is 1 in stage 3). No optimizations can be made to special-case handle jal without changing the pipeline.

#### 9. What is the most likely critical path in your design?
The most likely critical path is in stage 2. For example, the one going through IMEM + Mux + max(RegFileRead, ImmGen) + Mux(ASel/BSel) + ALU is pretty long.

#### 10. Where do the UART modules, instruction, and cycle counters go? How are you going to drive uart_tx_data_in_valid and uart_rx_data_out_ready (give logic expressions)?
The UART modules, instruction counter, and cycle counter go in the memory stage in parallel with the BIOS memory, IMEM, and DMEM. Extra logic (muxes + control signals) can be used to determine whether these devices are being accessed based on the memory map. \
uart_tx_data_in_valid = address == 32'h80000008 && inst == STORE; // Only want to have a transaction between our UART TX and an external UART RX if we are trying to transmit data using the TX \
uart_rx_data_out_ready = address == 32'h80000004 && inst == LOAD; // Only want to have a transaction between our UART RX and an external UART TX if we are trying to receive data using the RX

#### 11. What is the role of the CSR register? Where does it go?
The CSR register is used by CSR instructions. It goes in the memory stage in parallel with the memories + memory mapped I/O devices.

#### 12. When do we read from BIOS for instructions? When do we read from IMem for instructions? How do we switch from BIOS address space to IMem address space? In which case can we write to IMem, and why do we need to write to IMem? How do we know if a memory instruction is intended for DMem or any IO device?
We read from the BIOS for instructions when we first start up the CPU (corresponds to addresses with 4'b0100 as the top nibble). We read from IMem once we jump to the code we want to execute (corresponds to addresses with 4'b0001 as the top nibble). We switch from BIOS address space to IMem address space by executing a jal instruction in the BIOS program (corresponds to switching between BIOS instruction addresses which have 4'b0100 and reading IMem addresses which have 4'b0001). We can write to IMem while the BIOS program is running. IMem on startup has nothing so we need to write the program we want to run to IMem. We know that a memory instruction is intended for DMEM if it is fed into the input of DMEM and the top nibble is 4'00x1. We know a memory instruction is intended for an IO device if the address is in the memory map from addresses to devices.