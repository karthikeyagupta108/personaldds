`timescale 1ns / 1ps
// Automatic Washing Machine FSM (Gate-Level Model)

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

// Internal latch for start pulse
reg start_latched;

// --- Internal Wires ---
wire [2:0] next_state;
wire       d_start_latched;

// --- 1. Input/Signal Inverters ---
wire not_lid, not_cancel, not_start;
not n_lid(not_lid, lid);
not n_cancel(not_cancel, cancel);
not n_start(not_start, start);

// --- 2. Current State Decoders ---
wire not_state2, not_state1, not_state0;
not n_s2(not_state2, state[2]);
not n_s1(not_state1, state[1]);
not n_s0(not_state0, state[0]);

wire is_idle;   // 000
and a_idle(is_idle, not_state2, not_state1, not_state0);
wire is_ready;  // 001
and a_ready(is_ready, not_state2, not_state1, state[0]);
wire is_soak;   // 010
and a_soak(is_soak, not_state2, state[1], not_state0);
wire is_wash;   // 011
and a_wash(is_wash, not_state2, state[1], state[0]);
wire is_rinse;  // 100
and a_rinse(is_rinse, state[2], not_state1, not_state0);
wire is_spin;   // 101
and a_spin(is_spin, state[2], not_state1, state[0]);

// Unused states (110, 111) to default to IDLE
wire unused_110, unused_111, is_unused;
and a_u110(unused_110, state[2], state[1], not_state0);
and a_u111(unused_111, state[2], state[1], state[0]);
or or_unused(is_unused, unused_110, unused_111);

// --- 3. Transition Condition Logic ---
wire modes_selected;
or or_modes(modes_selected, mode1, mode2, mode3);

wire common_cond; // (lid == 0) && (cancel == 0)
and a_common(common_cond, not_lid, not_cancel);

// --- Transition Arcs ---
wire go_idle_to_ready;
and a_i_r(go_idle_to_ready, is_idle, common_cond, start_latched);

wire go_ready_to_soak;
and a_r_s(go_ready_to_soak, is_ready, common_cond, modes_selected);

wire go_soak_to_wash;
and a_g_s_w(go_soak_to_wash, is_soak, common_cond, timer_soak);

wire go_wash_to_rinse;
and a_w_r(go_wash_to_rinse, is_wash, common_cond, timer_wash);

wire go_rinse_to_spin;
and a_r_sp(go_rinse_to_spin, is_rinse, common_cond, timer_rinse);

wire go_spin_to_idle;
and a_sp_i(go_spin_to_idle, is_spin, common_cond, timer_spin);

// Cancel transition
wire active_states; // Any state except IDLE
or or_active(active_states, is_ready, is_soak, is_wash, is_rinse, is_spin);
wire go_cancel_to_idle;
and a_c_i(go_cancel_to_idle, active_states, cancel);

// --- Stay Conditions ---
wire not_go_idle_to_ready;
not n_i_r(not_go_idle_to_ready, go_idle_to_ready);
wire stay_idle;
and a_s_i(stay_idle, is_idle, not_go_idle_to_ready);

wire not_go_ready_to_soak;
not n_r_s(not_go_ready_to_soak, go_ready_to_soak);
wire stay_ready;
and a_s_r(stay_ready, is_ready, not_go_ready_to_soak, not_cancel);

wire not_go_soak_to_wash;
not n_s_w(not_go_soak_to_wash, go_soak_to_wash);
wire stay_soak;
and a_s_s(stay_soak, is_soak, not_go_soak_to_wash, not_cancel);

wire not_go_wash_to_rinse;
not n_w_r(not_go_wash_to_rinse, go_wash_to_rinse);
wire stay_wash;
and a_s_w(stay_wash, is_wash, not_go_wash_to_rinse, not_cancel);

wire not_go_rinse_to_spin;
not n_r_sp(not_go_rinse_to_spin, go_rinse_to_spin);
wire stay_rinse;
and a_s_ri(stay_rinse, is_rinse, not_go_rinse_to_spin, not_cancel);

wire not_go_spin_to_idle;
not n_sp_i(not_go_spin_to_idle, go_spin_to_idle);
wire stay_spin;
and a_s_sp(stay_spin, is_spin, not_go_spin_to_idle, not_cancel);

// --- 4. Next-State Logic (Sum-of-Products) ---
// Combine all conditions that lead to each future state
wire next_is_idle_cond;
or or_n_i(next_is_idle_cond, stay_idle, go_spin_to_idle, go_cancel_to_idle, is_unused);
wire next_is_ready_cond;
or or_n_r(next_is_ready_cond, go_idle_to_ready, stay_ready);
wire next_is_soak_cond;
or or_n_s(next_is_soak_cond, go_ready_to_soak, stay_soak);
wire next_is_wash_cond;
or or_n_w(next_is_wash_cond, go_soak_to_wash, stay_wash);
wire next_is_rinse_cond;
or or_n_ri(next_is_rinse_cond, go_wash_to_rinse, stay_rinse);
wire next_is_spin_cond;
or or_n_sp(next_is_spin_cond, go_rinse_to_spin, stay_spin);

// Build each bit of next_state
// next_state[2] is 1 for RINSE (100) and SPIN (101)
or or_ns2(next_state[2], next_is_rinse_cond, next_is_spin_cond);
// next_state[1] is 1 for SOAK (010) and WASH (011)
or or_ns1(next_state[1], next_is_soak_cond, next_is_wash_cond);
// next_state[0] is 1 for READY (001), WASH (011), and SPIN (101)
or or_ns0(next_state[0], next_is_ready_cond, next_is_wash_cond, next_is_spin_cond);

// --- 5. D-Input Logic for 'start_latched' ---
// d_start_latched = start | (~start & ~next_is_idle & start_latched);
wire not_ns2, not_ns1, not_ns0;
not n_ns2(not_ns2, next_state[2]);
not n_ns1(not_ns1, next_state[1]);
not n_ns0(not_ns0, next_state[0]);
wire next_is_idle; // Check if next_state is 000
and a_ns_idle(next_is_idle, not_ns2, not_ns1, not_ns0);

wire not_next_is_idle;
not n_ns_idle(not_next_is_idle, next_is_idle);

wire d_start_latched_term2;
and a_d_sl_t2(d_start_latched_term2, not_start, not_next_is_idle, start_latched);
or or_d_sl(d_start_latched, start, d_start_latched_term2);


// --- Sequential Logic (Registers) ---
// Replaces all 'always' blocks using ternary operator to avoid 'if'

// Latch the start signal
always @(posedge clk or negedge rst_n) begin
    start_latched <= rst_n ? d_start_latched : 1'b0;
end

// State register
always @(posedge clk or negedge rst_n) begin
    state[0] <= rst_n ? next_state[0] : 1'b0;
    state[1] <= rst_n ? next_state[1] : 1'b0;
    state[2] <= rst_n ? next_state[2] : 1'b0;
end

// Synchronous (Moore) output register block
always @(posedge clk or negedge rst_n) begin
    // D-inputs are the 'is_state' wires (e.g., d_soak_en = is_soak)
    soak_en  <= rst_n ? is_soak  : 1'b0;
    wash_en  <= rst_n ? is_wash  : 1'b0;
    rinse_en <= rst_n ? is_rinse : 1'b0;
    spin_en  <= rst_n ? is_spin  : 1'b0;
end

endmodule