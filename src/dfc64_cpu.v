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
    wire [7:0] acc_in;
    wire [7:0] acc_out;
    wire [7:0] x_in;
    wire [7:0] x_out;
    wire [7:0] y_in;
    wire [7:0] y_out;
    wire pc_jmp;
    wire pc_inc;
    wire reg_a_write;
    wire reg_x_write;
    wire reg_y_write;
    wire ir_set;
    wire drl_set;
    wire drh_set;

    assign uo_out = {3'b0, mre_set, mwe_set, ai_set, ahe_set, ale_set};
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, 1'b0};

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

    dfc64_reg_a reg_a (
        .rst_n(rst_n),
        .input_enable(reg_a_write),
        .data_input(acc_in),
        .reg_value(acc_out)
    );

    dfc64_reg_x reg_x (
        .rst_n(rst_n),
        .input_enable(reg_x_write),
        .data_input(x_in),
        .reg_value(x_out)
    );

    dfc64_reg_y reg_y (
        .rst_n(rst_n),
        .input_enable(reg_y_write),
        .data_input(y_in),
        .reg_value(y_out)
    );

    dfc64_control_unit control_unit (
      .clk(clk),
      .rst_n(rst_n),
      .uio_in(uio_in),
      .uio_out(uio_out),
      .uio_oe(uio_oe),
      .ir(ir),
      .pc(pc),
      .ale_set(ale_set),
      .ahe_set(ahe_set),
      .ai_set(ai_set),
      .mwe_set(mwe_set),
      .mre_set(mre_set),
      .pc_jmp(pc_jmp),
      .pc_inc(pc_inc),
      .reg_a_write(reg_a_write),
      .reg_a_output(acc_out),
      .reg_a_input(acc_in),
      .reg_x_write(reg_x_write),
      .reg_x_output(x_out),
      .reg_x_input(x_in),
      .reg_y_write(reg_y_write),
      .reg_y_output(y_out),
      .reg_y_input(y_in),
      .ir_set(ir_set),
      .drl_set(drl_set),
      .drh_set(drh_set)
    );

endmodule
