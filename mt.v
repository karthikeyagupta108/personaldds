`timescale 1ns / 1ps
module multi_phase_timer (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire [1:0] phase_sel,
    input  wire start,             // new cycle
    output reg  timer_done,
    output reg  [15:0] counter_out // expose counter
);

    reg [15:0] counter;
    reg [15:0] saved_counter;
    reg [15:0] limit;
    reg power_fail_detected;
    reg cycle_active;

    // Phase durations (simulated)
    always @(*) begin
        case(phase_sel)
            2'b00: limit = 16'd100;
            2'b01: limit = 16'd200;
            2'b10: limit = 16'd150;
            2'b11: limit = 16'd120;
            default: limit = 16'd100;
        endcase
    end

    // Timer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            saved_counter <= counter;
            power_fail_detected <= 1;
            timer_done <= 0;
            cycle_active <= 0;
        end else if (power_fail_detected) begin
            counter <= saved_counter;
            power_fail_detected <= 0;
            timer_done <= 0;
        end else if (start && !cycle_active) begin
            counter <= 0; cycle_active <= 1; timer_done <= 0;
        end else if (enable) begin
            if (counter < limit) begin
                counter <= counter + 1;
                timer_done <= 0;
            end else begin
                timer_done <= 1;
            end
        end else begin
            timer_done <= 0;
        end

        counter_out <= counter; // expose counter for monitoring
    end

endmodule

