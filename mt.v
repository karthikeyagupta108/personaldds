module multi_phase_timer (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,         // timer runs when enable = 1
    input  wire [1:0] phase_sel, // phase selection (soak, wash, rinse, spin)
    input  wire start,          // from washing machine FSM (new cycle)
    output reg  timer_done
);

    reg [15:0] counter;
    reg [15:0] saved_counter;
    reg [15:0] limit;
    reg power_fail_detected;
    reg [1:0] saved_phase;
    reg cycle_active;

    // Phase timing limits
    always @(*) begin
        case (phase_sel)
            2'b00: limit = 16'd100;  // soak
            2'b01: limit = 16'd200;  // wash
            2'b10: limit = 16'd150;  // rinse
            2'b11: limit = 16'd120;  // spin
            default: limit = 16'd100;
        endcase
    end

    // Timer operation with power resume and new-cycle reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Power goes off
            saved_counter <= counter;
            saved_phase <= phase_sel;
            power_fail_detected <= 1;
            timer_done <= 0;
            cycle_active <= 0;
        end 
        else if (power_fail_detected) begin
            // Power restored → resume
            counter <= saved_counter;
            power_fail_detected <= 0;
            timer_done <= 0;
        end 
        else if (start && !cycle_active) begin
            // New cycle start → reset counter
            counter <= 0;
            cycle_active <= 1;
            timer_done <= 0;
        end
        else if (enable) begin
            // Normal counting
            if (counter < limit) begin
                counter <= counter + 1;
                timer_done <= 0;
            end else begin
                timer_done <= 1;
            end
        end
        else begin
            timer_done <= 0;
        end
    end
endmodule
