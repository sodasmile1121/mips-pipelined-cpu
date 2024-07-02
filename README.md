# MIPS Pipelined Processor with Hazard Handling
![](./image/mips-pipelined-processor.svg)

By Inductiveload - Own work, Public Domain, https://commons.wikimedia.org/w/index.php?curid=5769084

<small>**Note:** The diagram sourced from Wikimedia Commons illustrates a generic pipelined processor architecture (without a forwarding unit and hazard detection unit). Although it differs from my specific implementation based on "Computer Organization and Design - The Hardware/Software Interface" (4th Edition), Figure 4.60, I have opted to use it for illustrative purposes and copyright considerations.</small>


## Description
This project implements a pipelined processor with hazard handling logic in Verilog/VHDL by adding forwarding and stalling features. 

## Features
- Implementation of MIPS instruction set architecture (ISA).
- 5-stage pipeline: Fetch, Decode, Execute, Memory, Writeback.
- Forwarding unit to prevent unnecessary stalls.
- Hazard detection unit manages data and control hazards, determining when stalling is necessary.
- Supports basic arithmetic and logical operations, load/store instructions, immediate instructions like addi, and branch instructions.

## Project Structure
- `src/`: Contains all necessary Verilog/VHDL code.
- `testbench/`: Test cases provided by TA for design validation.
- `image/`: Contains the architecture diagram of the MIPS pipelined processor.
- `docs/`: Includes experimental results and related Q&A.

## Code Structure

```
src/
├── alu.v # Arithmetic Logic Unit (ALU).
├── bit_alu.v # ALU's bit-level components excluding MSB.
├── msb_bit_alu.v # ALU's MSB component.
├── alu_control.v # Generates ALU control signals.
├── control.v # Generates overall control signals.
├── instr_mem.v # Instruction memory.
├── data_mem.v # Data memory.
├── reg_file.v # Register file.
├── forwarding.v # Handles data forwarding.
├── hazard_detection.v # Detects data and control hazards.
└── pipelined.v # Simulation entry point.
```

## Acknowledgement
I developed this project during my studies under Professor Yih-Lang Li at NYCU for Computer Organization. Many thanks to Professor Li and the TA for their invaluable guidance in enhancing my understanding of CPU architecture fundamentals.