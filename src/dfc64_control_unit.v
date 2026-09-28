module dfc64_control_unit (
    input clk,     // clock
    input rst_n,   // reset_n - low to reset
    input [7:0] uio_in,  // IOs: Input path
    output reg [7:0] uio_out,  // IOs: Output path
    output reg [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input [15:0] ar,
    input [23:0] ir,
    input [15:0] pc,
    output reg ale_set,
    output reg ahe_set,
    output reg ai_set,
    output reg mwe_set,
    output reg mre_set,
    output reg pc_jmp,
    output reg pc_inc,
    output reg pc_out,
    output reg ar_set_low,
    output reg ar_set_hi,
    output reg ir_set,
    output reg drl_set,
    output reg drh_set
);
    reg [3:0] stage;

    always @ (posedge clk or negedge rst_n) begin
            if (!rst_n)
                stage <= 4;
            else begin
                case (ir[7:0])
                    8'h4C: begin
                        case (stage)
                        // fetch second byte
                        //   enable bus out and lo address out
                            4'd4: begin
                                uio_oe = 8'hFF;
                                uio_out <= pc[7:0];
                                ale_set <= 1;
                                stage = stage + 1;
                            end
                        //   set output latch for low
                            4'd5: begin
                                ale_set <= 0;
                                stage = stage + 1;
                            end
                        //   enable bus out and hi address out
                            4'd6: begin
                                uio_oe = 8'hFF;
                                uio_out <= pc[15:8];
                                ale_set <= 1;
                                stage = stage + 1;
                            end
                        //   set output latch for hi
                            4'd7: begin
                                ale_set <= 0;
                                stage = stage + 1;
                            end
                        //   enable bus in and read data
                            4'd8: begin
                                uio_oe = 8'h00;
                                mre_set <= 1;
                                stage = stage + 1;
                            end
                        //   write bus data to ir
                            4'd9: begin
                                drl_set = 1;
                                pc_inc = 1;
                                stage = stage + 1;
                                mre_set <= 0;
                            end
                        // fetch third byte
                        //   enable bus out and lo address out
                            4'd10: begin
                                uio_oe = 8'hFF;
                                uio_out <= pc[7:0];
                                ale_set <= 1;
                                stage = stage + 1;
                            end
                        //   set output latch for low
                            4'd11: begin
                                ale_set <= 0;
                                stage = stage + 1;
                            end
                        //   enable bus out and hi address out
                            4'd12: begin
                                uio_oe = 8'hFF;
                                uio_out <= pc[15:8];
                                ale_set <= 1;
                                stage = stage + 1;
                            end
                        //   set output latch for hi
                            4'd13: begin
                                ale_set <= 0;
                                stage = stage + 1;
                            end
                        //   enable bus in and read data
                            4'd14: begin
                                uio_oe = 8'h00;
                                mre_set <= 1;
                                stage = stage + 1;
                            end
                        //   write bus data to ir and set pc
                            4'd15: begin
                                drh_set = 1;
                                pc_jmp = 1;
                                stage = 0;
                                mre_set <= 0;
                            end
                        endcase
                    end
                    default: begin
                    end
                endcase
            end
    end

endmodule
