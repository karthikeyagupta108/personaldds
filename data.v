`timescale 1ns / 1ps
module washing_machine_dataflow(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire cancel,
    input  wire lid,
    input  wire mode1, mode2, mode3,
    input  wire timer_done,
    output reg  [2:0] state,
    output reg  [1:0] phase_sel,
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

    reg [2:0] next_state;

    // Combinational next state (dataflow style)
    always @(*) begin
        case (state)
            IDLE:  next_state = (lid==0 && start && cancel==0) ? READY : IDLE;
            READY: next_state = (lid==0 && cancel==0 && (mode1|mode2|mode3)) ? SOAK :
                                (cancel ? IDLE : READY);
            SOAK:  next_state = (timer_done && cancel==0) ? WASH :
                                (cancel ? IDLE : SOAK);
            WASH:  next_state = (timer_done && cancel==0) ? RINSE :
                                (cancel ? IDLE : WASH);
            RINSE: next_state = (timer_done && cancel==0) ? SPIN :
                                (cancel ? IDLE : RINSE);
            SPIN:  next_state = (timer_done && cancel==0) ? IDLE :
                                (cancel ? IDLE : SPIN);
            default: next_state = IDLE;
        endcase
    end

    // Sequential update
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    // Phase selection (dataflow)
    always @(*) begin
        case (state)
            SOAK:  phase_sel = 2'b00;
            WASH:  phase_sel = 2'b01;
            RINSE: phase_sel = 2'b10;
            SPIN:  phase_sel = 2'b11;
            default: phase_sel = 2'b00;
        endcase
    end

    // Continuous assignments for enable signals
    assign soak_en  = (state == SOAK);
    assign wash_en  = (state == WASH);
    assign rinse_en = (state == RINSE);
    assign spin_en  = (state == SPIN);
    assign timer_enable = soak_en | wash_en | rinse_en | spin_en;

endmodule
