`timescale 1ns / 1ps
//====================================================================
// Washing Machine Gate-Level Model
// Compatible with multi_phase_timer.v and f189a70e testbench
//====================================================================

module washing_machine_gate_binary (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [1:0] phase_sel,
    output wire wash_enable,
    output wire rinse_enable,
    output wire dry_enable,
    output wire timer_done
);

    //------------------------------------------------------------
    // State registers
    //------------------------------------------------------------
    reg [2:0] current_state, next_state;

    // State encoding
    parameter IDLE  = 3'b000,
              WASH  = 3'b001,
              RINSE = 3'b010,
              DRY   = 3'b011,
              DONE  = 3'b100;

    //------------------------------------------------------------
    // Gate-Level Decoder for Output Enables
    //------------------------------------------------------------
    wire n2, n1, n0;
    wire n2a, n0a, n2b;

    not (n2, current_state[2]);
    not (n1, current_state[1]);
    not (n0, current_state[0]);

    // wash_enable = current_state == 3'b001
    and (wash_enable, n2, n1, current_state[0]);

    // rinse_enable = current_state == 3'b010
    not (n0a, current_state[0]);
    not (n2a, current_state[2]);
    and (rinse_enable, n2a, current_state[1], n0a);

    // dry_enable = current_state == 3'b011
    not (n2b, current_state[2]);
    and (dry_enable, n2b, current_state[1], current_state[0]);

    //------------------------------------------------------------
    // Timer Instance (Structural Integration)
    //------------------------------------------------------------
    multi_phase_timer timer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(wash_enable | rinse_enable | dry_enable),
        .phase_sel(phase_sel),
        .start(start),
        .timer_done(timer_done),
        .counter_out()
    );

    //------------------------------------------------------------
    // Sequential State Update (Behavioral)
    //------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //------------------------------------------------------------
    // Next-State Logic (Behavioral FSM)
    //------------------------------------------------------------
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:  if (start) next_state = WASH;
            WASH:  if (timer_done) next_state = RINSE;
            RINSE: if (timer_done) next_state = DRY;
            DRY:   if (timer_done) next_state = DONE;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule
