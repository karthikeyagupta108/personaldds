`timescale 1ns / 1ps
// ------------------------------------------------------------
// Automatic Washing Machine FSM
// With Power-Failure Resume Feature
// ------------------------------------------------------------
module washing_machine(
    input  wire clk,
    input  wire rst_n,        // active-low reset (power line)
    input  wire start,        // start button
    input  wire cancel,       // cancel button
    input  wire lid,          // 0=closed, 1=open
    input  wire mode1, mode2, mode3,
    input  wire timer_done,
    output reg  [2:0] state,
    output reg  [1:0] phase_sel,
    output reg  soak_en,
    output reg  wash_en,
    output reg  rinse_en,
    output reg  spin_en,
    output reg  timer_enable
);

// -----------------------------
// State definitions
// -----------------------------
localparam IDLE  = 3'd0,
           READY = 3'd1,
           SOAK  = 3'd2,
           WASH  = 3'd3,
           RINSE = 3'd4,
           SPIN  = 3'd5;

reg [2:0] next_state;
reg start_latched;

// New: for power resume feature
reg [2:0] saved_state;
reg power_fail_detected;

// -----------------------------
// Latch start button
// -----------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_latched <= 0;
    else if (start)
        start_latched <= 1;
    else if (next_state == IDLE)
        start_latched <= 0;
end

// -----------------------------
// Power failure detection and state restore
// -----------------------------
always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
        // Power failure: save current state
        saved_state <= state;
        power_fail_detected <= 1;
    end else if (power_fail_detected) begin
        // Power restored: resume previous state
        state <= saved_state;
        power_fail_detected <= 0;
    end else begin
        // Normal operation
        state <= next_state;
    end
end

// -----------------------------
// Next-state logic
// -----------------------------
always @(*) begin
    next_state   = state;
    phase_sel    = 2'b00;
    timer_enable = 0;

    case (state)
        IDLE: begin
            if (lid == 0 && start_latched && cancel == 0)
                next_state = READY;
        end

        READY: begin
            if (lid == 0 && cancel == 0 && (mode1 || mode2 || mode3))
                next_state = SOAK;
            else if (cancel)
                next_state = IDLE;
        end

        SOAK: begin
            phase_sel = 2'b00;
            timer_enable = 1;
            if (timer_done && cancel == 0 && lid == 0)
                next_state = WASH;
            else if (cancel)
                next_state = IDLE;
        end

        WASH: begin
            phase_sel = 2'b01;
            timer_enable = 1;
            if (timer_done && cancel == 0 && lid == 0)
                next_state = RINSE;
            else if (cancel)
                next_state = IDLE;
        end

        RINSE: begin
            phase_sel = 2'b10;
            timer_enable = 1;
            if (timer_done && cancel == 0 && lid == 0)
                next_state = SPIN;
            else if (cancel)
                next_state = IDLE;
        end

        SPIN: begin
            phase_sel = 2'b11;
            timer_enable = 1;
            if (timer_done && cancel == 0 && lid == 0)
                next_state = IDLE;
            else if (cancel)
                next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

// -----------------------------
// Output enables
// -----------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        soak_en  <= 0;
        wash_en  <= 0;
        rinse_en <= 0;
        spin_en  <= 0;
    end else begin
        soak_en  <= (state == SOAK);
        wash_en  <= (state == WASH);
        rinse_en <= (state == RINSE);
        spin_en  <= (state == SPIN);
    end
end

endmodule
