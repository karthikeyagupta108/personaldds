`timescale 1ns / 1ps
module washing_machine_gate_binary(
    input  wire clk,
    input  wire rst_n,       // active-low reset
    input  wire start,       // start button
    input  wire cancel,      // cancel button
    input  wire lid,         // lid = 0 closed, 1 open
    input  wire mode1, mode2, mode3, // wash modes
    input  wire timer_done,  // timer done pulse from timer
    output reg  [2:0] state, // FSM current state
    output reg  [1:0] phase_sel, // 00=soak, 01=wash, 10=rinse, 11=spin
    output wire soak_en,
    output wire wash_en,
    output wire rinse_en,
    output wire spin_en,
    output wire timer_enable  // signal to start timer
);

    // State Encoding
    localparam [2:0]
        IDLE  = 3'b000,
        READY = 3'b001,
        SOAK  = 3'b010,
        WASH  = 3'b011,
        RINSE = 3'b100,
        SPIN  = 3'b101;

    // Internal signals
    reg [2:0] next_state;
    reg start_latched;

    //======================================================
    // START LATCH (gate-level style logic)
    //======================================================
    wire start_or_state_reset;
    assign start_or_state_reset = start | (next_state == IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_latched <= 1'b0;
        else if (start)
            start_latched <= 1'b1;
        else if (next_state == IDLE)
            start_latched <= 1'b0;
    end

    //======================================================
    // STATE REGISTER
    //======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    //======================================================
    // NEXT STATE LOGIC (gate-level style using assigns)
    //======================================================
    wire lid_closed, not_cancel;
    assign lid_closed = ~lid;
    assign not_cancel = ~cancel;

    // Next state combinational block
    always @(*) begin
        next_state = state;
        phase_sel = 2'b00;

        case (state)
            IDLE: begin
                if (lid_closed & start_latched & not_cancel)
                    next_state = READY;
            end

            READY: begin
                if (lid_closed & not_cancel & (mode1 | mode2 | mode3))
                    next_state = SOAK;
                else if (cancel)
                    next_state = IDLE;
            end

            SOAK: begin
                phase_sel = 2'b00;
                if (lid_closed & not_cancel & timer_done)
                    next_state = WASH;
                else if (cancel)
                    next_state = IDLE;
            end

            WASH: begin
                phase_sel = 2'b01;
                if (lid_closed & not_cancel & timer_done)
                    next_state = RINSE;
                else if (cancel)
                    next_state = IDLE;
            end

            RINSE: begin
                phase_sel = 2'b10;
                if (lid_closed & not_cancel & timer_done)
                    next_state = SPIN;
                else if (cancel)
                    next_state = IDLE;
            end

            SPIN: begin
                phase_sel = 2'b11;
                if (lid_closed & not_cancel & timer_done)
                    next_state = IDLE;
                else if (cancel)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    //======================================================
    // TIMER ENABLE (gate-style)
    //======================================================
    assign timer_enable = (state == SOAK) |
                          (state == WASH) |
                          (state == RINSE) |
                          (state == SPIN);

    //======================================================
    // PHASE ENABLES (gate-style)
    //======================================================
    assign soak_en  = (state == SOAK);
    assign wash_en  = (state == WASH);
    assign rinse_en = (state == RINSE);
    assign spin_en  = (state == SPIN);

endmodule