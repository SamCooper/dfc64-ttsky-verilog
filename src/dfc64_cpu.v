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
    wire ar_set_low;
    wire ar_set_hi;
    wire ir_set;
    wire drl_set;
    wire drh_set;

    assign uo_out = {3'b0, mre_set, mwe_set, ai_set, ahe_set, ale_set};
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, ar_set_low, ar_set_hi, 1'b0};

    dfc64_program_counter program_counter (
      .pc_output(pc),
      .pc_input(ir[23:8]),
      .rst_n(rst_n),
      .jmp(pc_jmp),
      .inc(pc_inc)
    );

    dfc64_instruction_register instruction_register (
      .input_byte(uio_in),
      .rst_n(rst_n),
      .set_ir(ir_set),
      .set_drl(drl_set),
      .set_drh(drh_set),
      .instruction(ir)
    );

    dfc64_control_unit control_unit (
      .clk(clk),
      .rst_n(rst_n),
      .uio_out(uio_out),
      .uio_oe(uio_oe),
      .ir(ir[7:0]),
      .pc(pc),
      .ale_set(ale_set),
      .ahe_set(ahe_set),
      .ai_set(ai_set),
      .mwe_set(mwe_set),
      .mre_set(mre_set),
      .pc_jmp(pc_jmp),
      .pc_inc(pc_inc),
      .ar_set_low(ar_set_low),
      .ar_set_hi(ar_set_hi),
      .ir_set(ir_set),
      .drl_set(drl_set),
      .drh_set(drh_set)
    );

endmodule
