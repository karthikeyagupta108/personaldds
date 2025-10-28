`timescale 1ns / 1ps
module washing_machine_dataflow(
    input  wire clk,
    input  wire rst_n,       // active-low reset
    input  wire start,       // start button
    input  wire cancel,      // cancel button
    input  wire lid,         // lid = 0 closed, 1 open
    input  wire mode1, mode2, mode3, // wash modes
    input  wire timer_done,  // timer done pulse
    output reg  [2:0] state, // current state register
    output wire [1:0] phase_sel, // phase select
    output wire soak_en,
    output wire wash_en,
    output wire rinse_en,
    output wire spin_en,
    output wire timer_enable
);

    // State encoding
    localparam IDLE  = 3'd0,
               READY = 3'd1,
               SOAK  = 3'd2,
               WASH  = 3'd3,
               RINSE = 3'd4,
               SPIN  = 3'd5;

    // Start latch register
    reg start_latched;

    // Sequential: start latch
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            start_latched <= 1'b0;
        else if (start)
            start_latched <= 1'b1;
        else if (state == IDLE)
            start_latched <= 1'b0;

    // Next state combinational logic (dataflow style)
    wire [2:0] next_state;

    assign next_state =
        (state == IDLE  && lid==0 && start_latched && !cancel)                ? READY :
        (state == READY && lid==0 && !cancel && (mode1||mode2||mode3))        ? SOAK  :
        (state == READY && cancel)                                            ? IDLE  :
        (state == SOAK  && lid==0 && !cancel && timer_done)                   ? WASH  :
        (state == SOAK  && cancel)                                            ? IDLE  :
        (state == WASH  && lid==0 && !cancel && timer_done)                   ? RINSE :
        (state == WASH  && cancel)                                            ? IDLE  :
        (state == RINSE && lid==0 && !cancel && timer_done)                   ? SPIN  :
        (state == RINSE && cancel)                                            ? IDLE  :
        (state == SPIN  && lid==0 && !cancel && timer_done)                   ? IDLE  :
        (state == SPIN  && cancel)                                            ? IDLE  :
        state; // default: hold

    // Sequential: state register
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    // Dataflow-style output logic
    assign phase_sel =
        (state == SOAK)  ? 2'b00 :
        (state == WASH)  ? 2'b01 :
        (state == RINSE) ? 2'b10 :
        (state == SPIN)  ? 2'b11 : 2'b00;

    assign soak_en  = (state == SOAK);
    assign wash_en  = (state == WASH);
    assign rinse_en = (state == RINSE);
    assign spin_en  = (state == SPIN);

    assign timer_enable = (state == SOAK || state == WASH || state == RINSE || state == SPIN);

endmodule
