parameter REG_IR    = 4'b0000;
parameter REG_IR_L  = 4'b0001;
parameter REG_IR_H  = 4'b0010;
parameter REG_A     = 4'b0011;
parameter REG_X     = 4'b0100;
parameter REG_Y     = 4'b0101;
parameter REG_SP    = 4'b0110;
parameter REG_SR    = 4'b0111;
parameter REG_PCL   = 4'b1000;
parameter REG_PCH   = 4'b1001;
parameter REG_ALE   = 4'b1010;
parameter REG_AHE   = 4'b1011;
parameter REG_MEM   = 4'b1100;
parameter REG_ZERO  = 4'b1101;
parameter REG_ONE   = 4'b1110;

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
    // The storage array: registers, each 8 bits wide
    reg [7:0] rf [0:7];

    initial begin
        rf[REG_IR] = OP_JMP_ABS;
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
            default:  rdata1 = rf[rs1]; 
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
            default:  rdata2 = rf[rs2]; 
        endcase
    end

    assign ir_data[7:0] = rf[REG_IR];
    assign ir_data[15:8] = rf[REG_IR_L];
    assign ir_data[23:16] = rf[REG_IR_H];

    // WRITE LOGIC (Synchronous)
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rf[REG_IR] <= OP_JMP_ABS;
            rf[REG_SP] <= 8'hFF;
        end
        else begin
            // Only write if Write Enable is high AND we aren't trying to overwrite R0
            if (rst_n && we && rd != REG_ZERO && rd != REG_ONE) begin
                $display("%0t REG set %b %h!", $realtime, rd, wdata);
                rf[rd] <= wdata; 
            end
        end
    end

endmodule
