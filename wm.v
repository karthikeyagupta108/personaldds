`timescale 1ns / 1ps
module washing_machine(
    input  wire clk,
    input  wire rst_n,       // active-low reset
    input  wire start,       // start button
    input  wire cancel,      // cancel button
    input  wire lid,         // lid = 0 closed, 1 open
    input  wire mode1, mode2, mode3, // wash modes
    input  wire timer_done,  // timer done pulse from timer
    output reg  [2:0] state, // FSM current state
    output reg  [1:0] phase_sel, // 00=soak, 01=wash, 10=rinse, 11=spin
    output reg  soak_en,
    output reg  wash_en,
    output reg  rinse_en,
    output reg  spin_en,
    output reg  timer_enable   // signal to start timer
);

    localparam IDLE  = 3'd0,
               READY = 3'd1,
               SOAK  = 3'd2,
               WASH  = 3'd3,
               RINSE = 3'd4,
               SPIN  = 3'd5;

    reg [2:0] next_state;
    reg start_latched;

    // Latch start button
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_latched <= 0;
        else if (start)
            start_latched <= 1;
        else if (next_state == IDLE)
            start_latched <= 0;
    end

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= state; // hold state on power fail
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state    = state;
        phase_sel     = 2'b00;
        timer_enable  = 0;

        case (state)
            IDLE: if (lid==0 && start_latched && cancel==0) next_state = READY;

            READY: begin
                if (lid==0 && cancel==0 && (mode1||mode2||mode3)) next_state = SOAK;
                else if (cancel) next_state = IDLE;
            end

            SOAK: begin
                phase_sel = 2'b00; timer_enable=1;
                if (lid==0 && cancel==0 && timer_done) next_state = WASH;
                else if (cancel) next_state = IDLE;
            end

            WASH: begin
                phase_sel = 2'b01; timer_enable=1;
                if (lid==0 && cancel==0 && timer_done) next_state = RINSE;
                else if (cancel) next_state = IDLE;
            end

            RINSE: begin
                phase_sel = 2'b10; timer_enable=1;
                if (lid==0 && cancel==0 && timer_done) next_state = SPIN;
                else if (cancel) next_state = IDLE;
            end

            SPIN: begin
                phase_sel = 2'b11; timer_enable=1;
                if (lid==0 && cancel==0 && timer_done) next_state = IDLE;
                else if (cancel) next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output enables
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            soak_en<=0; wash_en<=0; rinse_en<=0; spin_en<=0;
        end else begin
            soak_en <= (state==SOAK);
            wash_en <= (state==WASH);
            rinse_en<= (state==RINSE);
            spin_en <= (state==SPIN);
        end
    end

endmodule
