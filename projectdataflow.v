`timescale 1ns / 1ps
// Automatic Washing Machine FSM (Dataflow Model)

module washing_machine(
    input  wire clk,
    input  wire rst_n,       // active-low reset
    input  wire start,       // start button
    input  wire cancel,      // cancel button
    input  wire lid,         // lid = 0 closed, 1 open
    input  wire mode1, mode2, mode3, // wash modes
    input  wire timer_soak,
    input  wire timer_wash,
    input  wire timer_rinse,
    input  wire timer_spin,
    output reg  [2:0] state,
    output reg  soak_en,
    output reg  wash_en,
    output reg  rinse_en,
    output reg  spin_en
);

// State encoding
localparam IDLE  = 3'd0,
           READY = 3'd1,
           SOAK  = 3'd2,
           WASH  = 3'd3,
           RINSE = 3'd4,
           SPIN  = 3'd5;

// --- Wires for D-Inputs to Registers ---

// D-input for the 'start_latched' register
wire d_start_latched;
// D-input for the 'state' register
wire [2:0] d_next_state;
// D-inputs for the output registers
wire d_soak_en;
wire d_wash_en;
wire d_rinse_en;
wire d_spin_en;

// --- Internal Latch Register ---
reg start_latched;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_latched <= 1'b0;
    else
        start_latched <= d_start_latched;
end

// --- State Register ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= d_next_state;
end

// --- Synchronous Output Registers ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        soak_en  <= 1'b0;
        wash_en  <= 1'b0;
        rinse_en <= 1'b0;
        spin_en  <= 1'b0;
    end else begin
        soak_en  <= d_soak_en;
        wash_en  <= d_wash_en;
        rinse_en <= d_rinse_en;
        spin_en  <= d_spin_en;
    end
end


// --- Dataflow Combinational Logic ---

// Logic for the 'start_latched' D-input
// Set if 'start' is pressed.
// Clear if 'd_next_state' (the *computed* next state) is IDLE.
// Hold otherwise.
assign d_start_latched = start | (start_latched & (d_next_state != IDLE));

// Next-state logic (combinational)
// This implements the case statement using nested ternary operators
assign d_next_state =
    (state == IDLE)  ? ((lid == 0 && start_latched && cancel == 0) ? READY : IDLE) :
    (state == READY) ? ((lid == 0 && cancel == 0 && (mode1 || mode2 || mode3)) ? SOAK : (cancel == 1) ? IDLE : READY) :
    (state == SOAK)  ? ((lid == 0 && cancel == 0 && timer_soak) ? WASH : (cancel == 1) ? IDLE : SOAK) :
    (state == WASH)  ? ((lid == 0 && cancel == 0 && timer_wash) ? RINSE : (cancel == 1) ? IDLE : WASH) :
    (state == RINSE) ? ((lid == 0 && cancel == 0 && timer_rinse) ? SPIN : (cancel == 1) ? IDLE : RINSE) :
    (state == SPIN)  ? ((lid == 0 && cancel == 0 && timer_spin) ? IDLE : (cancel == 1) ? IDLE : SPIN) :
    IDLE; // Default case

// Output logic (combinational)
// These feed the D-inputs of the synchronous output registers
// This is a Moore machine, so outputs depend *only* on the current 'state'
assign d_soak_en  = (state == SOAK);
assign d_wash_en  = (state == WASH);
assign d_rinse_en = (state == RINSE);
assign d_spin_en  = (state == SPIN);

endmodule