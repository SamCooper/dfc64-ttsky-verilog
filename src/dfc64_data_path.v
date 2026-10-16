module dfc64_data_path (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control Signals (Decoded by the Control Unit)
    input  wire        write_en,
    input  wire        mem_write,

    // bus IO wires
    input wire [7:0]  mem_in,
    output reg [7:0]  mem_out,
    output wire [7:0] mem_oe,     // IOs: Enable path (active high: 0=input, 1=output)
    output reg ale_set,
    output reg ahe_set,

    // Addresses (Directly from the 32-bit Instruction word)
    input  wire [3:0]  read_reg1,
    input  wire [3:0]  read_reg2,
    input  wire [3:0]  write_reg,
    
    // 8-bit Data Sources
    input  wire [7:0] alu_result, // Result of a math operation
    input  wire [15:0] pc,
    input  wire [7:0] sr,
    
    // 24-bit IR output
    output wire [23:0] ir_data,
    
    // 8-bit Outputs
    output wire [7:0] read_data1,
    output wire [7:0] read_data2
);
    // 1. THE MULTIPLEXER (Combinational Routing)
    // IOs: Enable path (active high: 0=input, 1=output)
    assign mem_oe = ((write_reg == REG_ALE) | (write_reg == REG_AHE) | mem_write) ? 8'hFF : 8'h00 ;
    assign ale_set = write_reg == REG_ALE ? 1 : 0;
    assign ahe_set = write_reg == REG_AHE ? 1 : 0;
    assign mem_out = alu_result;

    // 2. THE REGISTER FILE (Storage)
    dfc64_reg_file regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(write_en),
        .rs1(read_reg1),
        .rs2(read_reg2),
        .rd(write_reg),
        .wdata(alu_result),  // The MUX output feeds directly in here
        .mem_in(mem_in),
        .pc(pc),
        .sr(sr),
        .ir_data(ir_data),
        .rdata1(read_data1),
        .rdata2(read_data2)
    );

endmodule