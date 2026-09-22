# ASIC Multi-Block Logic Synthesis & Profiler Automation Flow

A modular Tcl-based automated flow for multi-block RTL logic synthesis and hardware metric profiling using Yosys Open SYnthesis Suite.

## Features
- **Automated Batch Synthesis**: Sequentially compiles and synthesizes RTL Verilog modules without manual intervention.
- **Robust Exception Handling**: Integrates Tcl `catch` and `error` commands to keep the flow running smoothly even if a module encounters an error.
- **Metric Extraction via Regex**: Accurately parses synthesis logs using regular expressions to extract design metrics:
  - Wire count
  - Generic cell/gate count
  - Sequential registers (D-Flip-Flops: standard, asynchronous reset, enable variants)
- **Formatted Reporting**: Automatically outputs structured ASCII comparison tables using Tcl string formatting (`format`).

## Project Structure
```text
asic_synth_flow/
├── rtl/
│   ├── alu.v           # 4-bit Combinational ALU module
│   └── fifo_buffer.v   # Sequential FIFO buffer module
├── synth_flow.tcl      # Main automation and parsing script
├── synth_summary.rpt   # Auto-generated synthesis summary report
├── .gitignore
└── README.md

