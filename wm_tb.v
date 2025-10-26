`timescale 1ns / 1ps
// ------------------------------------------------------------
// Testbench for Washing Machine with Power Resume
// ------------------------------------------------------------
module washing_machine_tb;

    reg clk, rst_n, start, cancel, lid;
    reg mode1, mode2, mode3;
    wire [2:0] state;
    wire [1:0] phase_sel;
    wire soak_en, wash_en, rinse_en, spin_en;
    wire timer_enable;
    wire timer_done;

    // -----------------------------
    // Clock generation
    // -----------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // -----------------------------
    // DUT Instantiation
    // -----------------------------
    washing_machine fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .cancel(cancel),
        .lid(lid),
        .mode1(mode1),
        .mode2(mode2),
        .mode3(mode3),
        .timer_done(timer_done),
        .state(state),
        .phase_sel(phase_sel),
        .soak_en(soak_en),
        .wash_en(wash_en),
        .rinse_en(rinse_en),
        .spin_en(spin_en),
        .timer_enable(timer_enable)
    );

    multi_phase_timer timer (
        .clk(clk),
        .rst_n(rst_n),
        .enable(timer_enable),
        .phase_sel(phase_sel),
        .timer_done(timer_done)
    );

    // -----------------------------
    // Stimulus
    // -----------------------------
    initial begin
        // Initialize inputs
        rst_n = 0; start = 0; cancel = 0; lid = 0;
        mode1 = 0; mode2 = 0; mode3 = 0;

        // Release reset
        #20 rst_n = 1;

        // Start washing cycle
        #10 start = 1; mode1 = 1; #10 start = 0;

        // Let it run for a while
        #800;

        // Simulate power failure during WASH
        $display("=== POWER FAILURE ===");
        rst_n = 0;
        #50;
        $display("=== POWER RESTORED ===");
        rst_n = 1;

        // Continue running
        #1000;

        // End simulation
        $finish;
    end

    // -----------------------------
    // Monitor state transitions
    // -----------------------------
    always @(posedge clk) begin
        $display("Time=%0t | State=%0d | PhaseSel=%b | TimerEn=%b | TimerDone=%b | soak=%b wash=%b rinse=%b spin=%b",
                 $time, state, phase_sel, timer_enable, timer_done,
                 soak_en, wash_en, rinse_en, spin_en);
    end

endmodule
