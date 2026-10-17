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
    wire zp_clr_set;
    wire mwe_set;
    wire mre_set;
    wire [23:0] ir;
    wire [15:0] pc;
    wire  [7:0] sr;

    wire alu_carry;
    wire alu_zero;
    wire alu_negative;

    wire reg_sr_set;
    wire reg_sr_full_set;
    wire alu_sub;
    wire set_addr_c;
    wire pc_jmp;
    wire pc_inc;

    wire        write_en;
    wire [3:0]  read_reg_sel1;
    wire [3:0]  read_reg_sel2;
    wire [3:0]  write_reg_sel;
    wire [7:0] alu_result;
    wire [7:0] mux_data1;
    wire [7:0] mux_data2;

    // The pins match the inputs of the off-chip 74HC163s and the memory (active-low where
    // the chip pin is active-low); inside the CPU every strobe is active-high.
    assign uo_out = {2'b0,
                     ~zp_clr_set,   // [5] ZP_CLR_n  -> SR_n of the upper counters
                     ~mre_set,      // [4] MEM_OE_n  -> memory OE_n
                     ~mwe_set,      // [3] MEM_WE_n  -> memory WE_n
                     ai_set,        // [2] ADDR_INC  -> CEP of the counters (active-high)
                     ~ahe_set,      // [1] LOAD_H_n  -> PE_n of the upper counters
                     ~ale_set};     // [0] LOAD_L_n  -> PE_n of the lower counters

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

    dfc64_sr status_register (
        .clk(clk),
        .rst_n(rst_n),

        .write_enable(reg_sr_set),
        .full_write_mode(reg_sr_full_set), // 0 = Update individual flags, 1 = Overwrite all
        
        .full_word_in(alu_result),     // From standard data bus (e.g., for POP instruction)
        .alu_carry_in(alu_carry),    // From ALU
        .alu_zero_in(alu_zero),     // From ALU
        .alu_negative_in(alu_negative), // From ALU

        .status_out(sr)
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
        .sr(sr),
    
        // 8-bit Outputs
        .ir_data(ir),
        .read_data1(mux_data1),
        .read_data2(mux_data2)
    );

    dfc64_alu alu (
      .clk(clk),
      .rst_n(rst_n),

      .sub(alu_sub),
      .set_addr_c(set_addr_c),

      .src_data1(mux_data1),
      .src_data2(mux_data2),

      .alu_carry(alu_carry),    // From ALU
      .alu_zero(alu_zero),     // From ALU
      .alu_negative(alu_negative), // From ALU

      .result_data(alu_result)
    );

    dfc64_control_unit control_unit (
      .clk(clk),
      .rst_n(rst_n),
      .ir(ir),
      .mem_in(uio_in),

      .reg_sr_set(reg_sr_set),
      .reg_sr_full_set(reg_sr_full_set),
      .alu_sub(alu_sub),
      .set_addr_c(set_addr_c),
      .al_inc(ai_set),
      .zp_clr_set(zp_clr_set),
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
