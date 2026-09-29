module dfc64_control_unit (
    input clk,     // clock
    input rst_n,   // reset_n - low to reset
    input [7:0] uio_in,  // IOs: Input path
    output reg [7:0] uio_out,  // IOs: Output path
    output reg [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input [23:0] ir,
    input [15:0] pc,
    output reg ale_set,
    output reg ahe_set,
    output reg ai_set,
    output reg mwe_set,
    output reg mre_set,
    output reg pc_jmp,
    output reg pc_inc,
    output reg ar_set_low,
    output reg ar_set_hi,
    output reg ir_set,
    output reg drl_set,
    output reg drh_set
);
    reg [3:0] stage;

    always @ (posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                    $display("Reset!");
                    stage <= 4;
                end
            else begin
                ale_set = 0;
                ahe_set = 0;
                ai_set = 0;
                mwe_set = 0;
                mre_set = 0;
                pc_jmp = 0;
                pc_inc = 0;
                ar_set_low = 0;
                ar_set_hi = 0;
                ir_set = 0;
                drl_set = 0;
                drh_set = 0;

                case (stage)
                // fetch first byte
                //   enable bus out and lo address out
                    4'd0: begin
                        uio_oe = 8'hFF;
                        uio_out <= pc[7:0];
                        ale_set <= 1;
                        stage = stage + 1;
                    end
                //   enable bus out and hi address out
                    4'd1: begin
                        uio_out <= pc[15:8];
                        ahe_set <= 1;
                        stage = stage + 1;
                    end
                //   enable bus in and read data
                    4'd2: begin
                        uio_oe = 8'h00;
                        mre_set <= 1;
                        stage = stage + 1;
                    end
                //   write bus data to ir
                    4'd3: begin
                        ir_set = 1;
                        pc_inc = 1;
                        stage = stage + 1;
                    end
                    default: begin
                        case (ir[7:0])
                            8'h4C: begin
                                $display("Stage %d!", stage);
                                case (stage)
                                // fetch second byte
                                //   enable bus out and lo address out
                                    4'd4: begin
                                        uio_oe = 8'hFF;
                                        uio_out <= pc[7:0];
                                        ale_set <= 1;
                                        stage = stage + 1;
                                    end
                                //   enable bus out and hi address out
                                    4'd5: begin
                                        uio_out <= pc[15:8];
                                        ahe_set <= 1;
                                        stage = stage + 1;
                                    end
                                //   enable bus in and read data
                                    4'd6: begin
                                        uio_oe = 8'h00;
                                        mre_set <= 1;
                                        stage = stage + 1;
                                    end
                                //   write bus data to ir
                                    4'd7: begin
                                        drl_set = 1;
                                        pc_inc = 1;
                                        stage = stage + 1;
                                    end
                                // fetch third byte
                                //   enable bus out and lo address out
                                    4'd8: begin
                                        uio_oe = 8'hFF;
                                        uio_out <= pc[7:0];
                                        ale_set <= 1;
                                        stage = stage + 1;
                                    end
                                //   enable bus out and hi address out
                                    4'd9: begin
                                        uio_out <= pc[15:8];
                                        ahe_set <= 1;
                                        stage = stage + 1;
                                    end
                                //   enable bus in and read data
                                    4'd10: begin
                                        uio_oe = 8'h00;
                                        mre_set <= 1;
                                        stage = stage + 1;
                                    end
                                //   write bus data to ir and set pc
                                    4'd11: begin
                                        drh_set = 1;
                                        stage = 0;
                                        pc_jmp <= 1;
                                    end
                                endcase
                            end
                            default: begin
                            end
                        endcase
                    end
                    endcase
            end
    end

endmodule
