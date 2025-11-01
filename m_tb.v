`timescale 1ns / 1ps
module tb_washing_machine;

    reg clk, rst_n, start, cancel, lid;
    reg mode1, mode2, mode3;
    wire [2:0] state;
    wire [1:0] phase_sel;
    wire soak_en, wash_en, rinse_en, spin_en;
    wire timer_enable, timer_done;
    wire [15:0] counter_out;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate Timer module (common for all)
    multi_phase_timer timer(
        .clk(clk), 
        .rst_n(rst_n), 
        .enable(timer_enable), 
        .phase_sel(phase_sel), 
        .start(start), 
        .timer_done(timer_done), 
        .counter_out(counter_out)
    );

    // Instantiate one washing machine controller model at a time
    // Uncomment the module you want to test

    // Gate-level model
    washing_machine_gate_binary fsm(
        .clk(clk), .rst_n(rst_n), .start(start), .cancel(cancel), .lid(lid),
        .mode1(mode1), .mode2(mode2), .mode3(mode3),
        .timer_done(timer_done),
        .state(state), .phase_sel(phase_sel),
        .soak_en(soak_en), .wash_en(wash_en),
        .rinse_en(rinse_en), .spin_en(spin_en),
        .timer_enable(timer_enable)
    );

    //Dataflow model
    // washing_machine_dataflow fsm(
    //     .clk(clk), .rst_n(rst_n), .start(start), .cancel(cancel), .lid(lid),
    //     .mode1(mode1), .mode2(mode2), .mode3(mode3),
    //     .timer_done(timer_done),
    //     .state(state), .phase_sel(phase_sel),
    //     .soak_en(soak_en), .wash_en(wash_en),
    //     .rinse_en(rinse_en), .spin_en(spin_en),
    //     .timer_enable(timer_enable)
    // );

    // // Behavioral model
    // washing_machine fsm(
    //     .clk(clk), .rst_n(rst_n), .start(start), .cancel(cancel), .lid(lid),
    //     .mode1(mode1), .mode2(mode2), .mode3(mode3),
    //     .timer_done(timer_done),
    //     .state(state), .phase_sel(phase_sel),
    //     .soak_en(soak_en), .wash_en(wash_en),
    //     .rinse_en(rinse_en), .spin_en(spin_en),
    //     .timer_enable(timer_enable)
    // );

    // VCD dump for waveform viewing
    initial begin
        $dumpfile("washing_machine.vcd");
        $dumpvars(0, tb_washing_machine);
    end

    // Test stimulus
    initial begin
        $monitor("  Time=%0ds       State=%0d       Phase=%b        Timer=%0d       timer_done=%b     ",
        
        $time, state, phase_sel, counter_out, timer_done);

        

        rst_n = 0; start = 0; cancel = 0; lid = 0;
        mode1 = 0; mode2 = 1; mode3 = 0;

        #20 rst_n = 1;
        #10 start = 1; lid = 0;
        #10 start = 0;

        // Optional: simulate power failure mid-cycle
        #1500 rst_n = 0;  // power off
        #100  rst_n = 1;  // power on

        // Wait until FSM returns to IDLE (state 0)
        wait(state == 3'd0);
        $display(" Washing cycle completed at time %0t\n", $time);
        $finish;
    end

endmodule