`timescale 1ns / 1ps
module multi_phase_timer(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire [1:0] phase_sel,
    input  wire mode1, mode2, mode3,
    input  wire start,
    output reg  timer_done,
    output reg [31:0] counter_out
);

    reg [31:0] max_count;

    // Duration of each phase depending on mode
    always @(*) begin
        case ({mode1, mode2, mode3})
            3'b100: begin // Quick Wash
                case (phase_sel)
                    2'b00: max_count = 32'd50;
                    2'b01: max_count = 32'd100;
                    2'b10: max_count = 32'd80;
                    2'b11: max_count = 32'd55;
                    default: max_count = 32'd0;
                endcase
            end
            3'b010: begin // Normal Wash
                case (phase_sel)
                    2'b00: max_count = 32'd100;
                    2'b01: max_count = 32'd200;
                    2'b10: max_count = 32'd150;
                    2'b11: max_count = 32'd120;
                    default: max_count = 32'd0;
                endcase
            end
            3'b001: begin // Heavy Wash
                case (phase_sel)
                    2'b00: max_count = 32'd150;
                    2'b01: max_count = 32'd300;
                    2'b10: max_count = 32'd220;
                    2'b11: max_count = 32'd160;
                    default: max_count = 32'd0;
                endcase
            end
            default: max_count = 32'd0;
        endcase
    end

    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_out <= 0;
            timer_done  <= 0;
        end else if (!enable) begin
            counter_out <= 0;
            timer_done  <= 0;
        end else begin
            if (counter_out >= max_count) begin
                timer_done  <= 1;
                counter_out <= 0;
            end else begin
                counter_out <= counter_out + 1;
                timer_done  <= 0;
            end
        end
    end

endmodule
