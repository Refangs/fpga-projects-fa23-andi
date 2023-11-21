.section    .start
.global     _start

_start:

# Follow a convention
# x1 = result register 1
# x2 = result register 2
# x10 = argument 1 register
# x11 = argument 2 register
# x20 = flag register

# Test ADD
li x10, 100         # Load argument 1 (rs1)
li x11, 200         # Load argument 2 (rs2)
add x1, x10, x11    # Execute the instruction being tested
li x20, 1           # Set the flag register to stop execution and inspect the result register
                    # Now we check that x1 contains 300

# Test BEQ
li x2, 100          # Set an initial value of x2
beq x0, x0, branch1 # This branch should succeed and jump to branch1
li x2, 123          # This shouldn't execute, but if it does x2 becomes an undesirable value
branch1: li x1, 500 # x1 now contains 500
li x20, 2           # Set the flag register
                    # Now we check that x1 contains 500 and x2 contains 100

# TODO: add more tests here

#Test JALR
auipc x10, 0        # 0
addi x10, x10, 16   # 4
jalr x1, x10        # 8
j skip              # 12    jalr should not jump to this line
li x2, 900          # 16    jalr should jump to this line
j end
skip: li x2, 123
end: li x20, 3      # Set flag register
                    # Check that x2 holds 900 and not 123.

#Test JALR (isa test)
#li x3, 2
#li x5, 0
#auipc x6, 0x0
#addi x6, x6, 16
#jalr x5, x6
#j fail
#auipc x6, 0x0
#li x2, 900
#li x20, 3


done: j done
