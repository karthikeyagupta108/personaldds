`timescale 1ns / 1ps
module multi_phase_timer(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire [1:0] phase_sel,
    input  wire mode1, mode2, mode3, mode4,
    input  wire start,
    input  wire power_on,          // NEW: handles power cut/resume
    output reg  timer_done,
    output reg [31:0] counter_out
);

    reg [31:0] max_count;

    // ============================================================
    // Select duration for each phase depending on active mode
    // ============================================================
    always @(*) begin
        case ({mode1, mode2, mode3, mode4})
            4'b1000: begin // Quick Wash
                case (phase_sel)
                    2'b00: max_count = 32'd50;
                    2'b01: max_count = 32'd100;
                    2'b10: max_count = 32'd80;
                    2'b11: max_count = 32'd55;
                    default: max_count = 32'd0;
                endcase
            end

            4'b0100: begin // Normal Wash
                case (phase_sel)
                    2'b00: max_count = 32'd100;
                    2'b01: max_count = 32'd200;
                    2'b10: max_count = 32'd150;
                    2'b11: max_count = 32'd120;
                    default: max_count = 32'd0;
                endcase
            end

            4'b0010: begin // Heavy Wash
                case (phase_sel)
                    2'b00: max_count = 32'd150;
                    2'b01: max_count = 32'd300;
                    2'b10: max_count = 32'd220;
                    2'b11: max_count = 32'd160;
                    default: max_count = 32'd0;
                endcase
            end

            4'b0001: begin // Spin-Only Mode (no soak/wash/rinse)
                max_count = 32'd40; // fixed 40-second spin
            end

            default: max_count = 32'd0;
        endcase
    end

    // ============================================================
    // Counter Logic — pauses if power is off
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_out <= 0;
            timer_done  <= 0;
        end
        else if (!enable || !power_on) begin
            // Pause or reset depending on enable
            if (!enable) counter_out <= 0;
            timer_done  <= 0;
        end
        else begin
            if (counter_out >= max_count) begin
                timer_done  <= 1;
                counter_out <= 0;
            end
            else begin
                counter_out <= counter_out + 1;
                timer_done  <= 0;
            end
        end
    end

endmodule
