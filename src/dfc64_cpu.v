/*
 * Copyright (c) 2026 Sam Cooper
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/* verilator lint_off DECLFILENAME */
module tt_um_samcooper_dfc64 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    wire ale_set;
    wire ahe_set;
    wire ai_set;
    wire mwe_set;
    wire mre_set;
    wire [23:0] ir;
    wire [15:0] pc;
    wire pc_jmp;
    wire pc_inc;

    wire        write_en;
    wire [3:0]  read_reg_sel1;
    wire [3:0]  read_reg_sel2;
    wire [3:0]  write_reg_sel;
    wire [7:0] alu_result;
    wire [7:0] mux_data1;
    wire [7:0] mux_data2;

    assign uo_out = {3'b0, mre_set, mwe_set, ai_set, ahe_set, ale_set};

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, 1'b0};

    dfc64_program_counter program_counter (
      .clk(clk),
      .pc_output(pc),
      .pc_input(ir[23:8]),
      .rst_n(rst_n),
      .jmp(pc_jmp),
      .inc(pc_inc)
    );

    dfc64_data_path data_path (
        .clk(clk),
        .rst_n(rst_n),

        // Control Signals (Decoded by the Control Unit)
        .write_en(write_en),
        .mem_write(mwe_set), 

        // bus IO wires
        .mem_in(uio_in),   // Data loaded from RAM
        .mem_out(uio_out),   // Data loaded from RAM
        .mem_oe(uio_oe),
        .ale_set(ale_set),
        .ahe_set(ahe_set),
    
        // Addresses
        .read_reg1(read_reg_sel1),
        .read_reg2(read_reg_sel2),
        .write_reg(write_reg_sel),
    
        // 8-bit Data Sources
        .alu_result(alu_result), // Result of a math operation
        .pc(pc),
    
        // 8-bit Outputs
        .ir_data(ir),
        .read_data1(mux_data1),
        .read_data2(mux_data2)
    );

    dfc64_alu alu (
      .src_data1(mux_data1),
      .src_data2(mux_data2),
      .result_data(alu_result)
    );

    dfc64_control_unit control_unit (
      .clk(clk),
      .rst_n(rst_n),
      .ir(ir),

      .pc_jmp(pc_jmp),
      .pc_inc(pc_inc),

      .mem_write_en(mwe_set),
      .mem_read_en(mre_set),
      .write_en(write_en),

      .read_reg_sel1(read_reg_sel1),
      .read_reg_sel2(read_reg_sel2),
      .write_reg_sel(write_reg_sel)
    );

endmodule
