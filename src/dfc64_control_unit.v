module dfc64_control_unit (
    input clk,     // clock
    input rst_n,   // reset_n - low to reset
    output reg [7:0] uio_out,  // IOs: Output path
    output reg [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input [7:0] ir,
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
    localparam FETCH_1_STAGE_1 = 4'd0;
    localparam FETCH_1_STAGE_2 = 4'd1;
    localparam FETCH_1_STAGE_3 = 4'd2;
    localparam FETCH_2_STAGE_1 = 4'd3;
    localparam FETCH_2_STAGE_2 = 4'd4;
    localparam FETCH_2_STAGE_3 = 4'd5;
    localparam FETCH_3_STAGE_1 = 4'd6;
    localparam FETCH_3_STAGE_2 = 4'd7;
    localparam FETCH_3_STAGE_3 = 4'd8;
    localparam EXECUTE_STAGE = 4'd9;
    reg [3:0] stage;

    wire [7:0] op = ir[7:0]; // Your fetched opcode

    // 0 Extra Bytes: BRK/RTI/RTS, or ends in 8 or A
    wire needs_zero_extra = (op == 8'h00) || (op == 8'h40) || (op == 8'h60) || 
                            ({op[3], op[2], op[0]} == 3'b100);

    // 2 Extra Bytes: JSR (0x20), or ends in 9, C, D, or E
    wire needs_two_extra = (op == 8'h20) || 
                        (op[3:0] == 4'h9) || 
                        (op[3:2] == 2'b11);

    // Default to 1 Extra Byte
    wire needs_one_extra = !(needs_two_extra || needs_zero_extra);

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
                // $display("Reset!");
                stage <= 3;
            end
        else begin
            ale_set <= 0;
            ahe_set <= 0;
            ai_set <= 0;
            mwe_set <= 0;
            mre_set <= 0;
            pc_jmp <= 0;
            pc_inc <= 0;
            ar_set_low <= 0;
            ar_set_hi <= 0;
            ir_set <= 0;
            drl_set <= 0;
            drh_set <= 0;

            if ((needs_zero_extra && (stage > FETCH_1_STAGE_3)) ||
                (needs_one_extra && (stage > FETCH_2_STAGE_3)) ||
                (needs_two_extra && (stage > FETCH_3_STAGE_3))) begin
                // $display("Stage exe, z %d, 1 %d, 2 %d", needs_zero_extra, needs_one_extra, needs_two_extra);
                stage <= EXECUTE_STAGE;

                case (ir[7:0])
                    OP_JMP_ABS: begin
                        pc_inc <= 0;
                        pc_jmp <= 1;
                        stage <= FETCH_1_STAGE_1;
                    end
                    default: begin
                        stage <= FETCH_1_STAGE_1;
                    end
                endcase
            end
            else begin
                // $display("Stage %d, z %d, 1 %d, 2 %d", stage, needs_zero_extra, needs_one_extra, needs_two_extra);

                case (stage)
                    FETCH_1_STAGE_1,
                    FETCH_2_STAGE_1,
                    FETCH_3_STAGE_1: begin
                        uio_oe <= 8'hFF;
                        uio_out <= pc[7:0];
                        ale_set <= 1;
                        stage <= stage + 1;
                    end
                    FETCH_1_STAGE_2,
                    FETCH_2_STAGE_2,
                    FETCH_3_STAGE_2: begin
                        uio_out <= pc[15:8];
                        ahe_set <= 1;
                        mre_set <= 1;
                        stage <= stage + 1;
                    end
                    FETCH_1_STAGE_3: begin
                        uio_oe <= 8'h00;
                        mre_set <= 1;
                        ir_set <= 1;
                        pc_inc <= 1;
                        stage <= stage + 1;
                    end
                    FETCH_2_STAGE_3: begin
                        uio_oe <= 8'h00;
                        mre_set <= 1;
                        drl_set <= 1;
                        pc_inc <= 1;
                        stage <= stage + 1;
                    end
                    FETCH_3_STAGE_3: begin
                        uio_oe <= 8'h00;
                        mre_set <= 1;
                        drh_set <= 1;
                        pc_inc <= 1;
                        stage <= stage + 1;
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

endmodule
