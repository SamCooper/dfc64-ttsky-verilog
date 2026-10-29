module dfc64_reg_file (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        we,         // Write Enable (from Control Unit)
    input  wire [3:0]  rs1,        // Read Address 1 
    input  wire [3:0]  rs2,        // Read Address 2 
    input  wire [3:0]  rd,         // Write Address 
    input  wire [7:0]  wdata,      // Data to write (from the MUX)
    input  wire [7:0]  mem_in,
    input  wire [15:0] pc,
    input  wire [7:0]  sr,
    
    output wire [23:0] ir_data,    // 24-bit IR output
    
    output reg [7:0]  rdata1,     // Data out 1 (goes to ALU)
    output reg [7:0]  rdata2      // Data out 2 (goes to ALU)
);
    localparam REG_IR    = 4'b0000;
    localparam REG_IR_L  = 4'b0001;
    localparam REG_IR_H  = 4'b0010;
//    localparam REG_A     = 4'b0011;
//    localparam REG_X     = 4'b0100;
//    localparam REG_Y     = 4'b0101;
    localparam REG_SP    = 4'b0110;
    localparam REG_SR    = 4'b0111;
    localparam REG_PCL   = 4'b1000;
    localparam REG_PCH   = 4'b1001;
//    localparam REG_ALE   = 4'b1010;
//    localparam REG_AHE   = 4'b1011;
    localparam REG_MEM   = 4'b1100;
    localparam REG_ZERO  = 4'b1101;
    localparam REG_ONE   = 4'b1110;

    // The storage array: registers, each 8 bits wide
    reg [7:0] rf [0:6];

    initial begin
        rf[REG_IR[2:0]] = OP_JMP_ABS;
    end

    // READ LOGIC (Combinational)
    always @(*) begin
        case (rs1)
            REG_ZERO: rdata1 = 8'b0;
            REG_ONE:  rdata1 = 8'b1;
            REG_SR:   rdata1 = sr;
            REG_PCL:  rdata1 = pc[7:0];
            REG_PCH:  rdata1 = pc[15:8];
            REG_MEM:  rdata1 = mem_in;
            default:  rdata1 = rf[rs1[2:0]]; 
        endcase
    end
    always @(*) begin
        case (rs2)
            REG_ZERO: rdata2 = 8'b0;
            REG_ONE:  rdata2 = 8'b1;
            REG_SR:   rdata2 = sr;
            REG_PCL:  rdata2 = pc[7:0];
            REG_PCH:  rdata2 = pc[15:8];
            REG_MEM:  rdata2 = mem_in;
            default:  rdata2 = rf[rs2[2:0]]; 
        endcase
    end

    assign ir_data[7:0] = rf[REG_IR[2:0]];
    assign ir_data[15:8] = rf[REG_IR_L[2:0]];
    assign ir_data[23:16] = rf[REG_IR_H[2:0]];

    // WRITE LOGIC (Synchronous)
    always @ (posedge clk) begin
        if (!rst_n) begin
            rf[REG_IR[2:0]] <= OP_JMP_ABS;
            rf[REG_SP[2:0]] <= 8'hFF;
        end
        else begin
            // Only write if Write Enable is high AND we aren't trying to overwrite R0
            if (rst_n && we && rd[3] == 0) begin
                `ifdef SIM
                    $display("%0t REG set %b %h!", $realtime, rd, wdata);
                `endif
                rf[rd[2:0]] <= wdata; 
            end
        end
    end

endmodule
