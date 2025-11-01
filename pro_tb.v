`timescale 1ns / 1ps
module tb_washing_machine;

    reg clk, rst_n, start, cancel, lid;
    reg mode1, mode2, mode3;
    wire [2:0] state;
    wire [1:0] phase_sel;
    wire soak_en, wash_en, rinse_en, spin_en;
    wire timer_enable, timer_done;
    wire [31:0] counter_out;

    integer start_time, end_time;

    // ====================================================
    // SELECT MODEL: 0=Behavioral, 1=Dataflow, 2=Gate-level
    // ====================================================
    parameter MODEL_SELECT = 2;
    // ====================================================
    // SELECT MODE: 1=Quick, 2=Normal, 3=Heavy
    // ====================================================
    parameter TEST_MODE = 3;
    // ====================================================

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Timer instantiation
    multi_phase_timer timer(
        .clk(clk), 
        .rst_n(rst_n), 
        .enable(timer_enable), 
        .phase_sel(phase_sel),
        .mode1(mode1), .mode2(mode2), .mode3(mode3),
        .start(start), 
        .timer_done(timer_done), 
        .counter_out(counter_out)
    );

    // FSM model selection
    generate
        if (MODEL_SELECT == 0) begin
            washing_machine fsm(
                .clk(clk), .rst_n(rst_n), .start(start), .cancel(cancel), .lid(lid),
                .mode1(mode1), .mode2(mode2), .mode3(mode3),
                .timer_done(timer_done),
                .state(state), .phase_sel(phase_sel),
                .soak_en(soak_en), .wash_en(wash_en),
                .rinse_en(rinse_en), .spin_en(spin_en),
                .timer_enable(timer_enable)
            );
        end else if (MODEL_SELECT == 1) begin
            washing_machine_dataflow fsm(
                .clk(clk), .rst_n(rst_n), .start(start), .cancel(cancel), .lid(lid),
                .mode1(mode1), .mode2(mode2), .mode3(mode3),
                .timer_done(timer_done),
                .state(state), .phase_sel(phase_sel),
                .soak_en(soak_en), .wash_en(wash_en),
                .rinse_en(rinse_en), .spin_en(spin_en),
                .timer_enable(timer_enable)
            );
        end else begin
            washing_machine_gate fsm(
                .clk(clk), .rst_n(rst_n), .start(start), .cancel(cancel), .lid(lid),
                .mode1(mode1), .mode2(mode2), .mode3(mode3),
                .timer_done(timer_done),
                .state(state), .phase_sel(phase_sel),
                .soak_en(soak_en), .wash_en(wash_en),
                .rinse_en(rinse_en), .spin_en(spin_en),
                .timer_enable(timer_enable)
            );
        end
    endgenerate

    // Phase name mapper
    function [79:0] phase_name;
        input [2:0] state;
        begin
            case (state)
                3'd0: phase_name = "IDLE ";
                3'd2: phase_name = "SOAK ";
                3'd3: phase_name = "WASH ";
                3'd4: phase_name = "RINSE";
                3'd5: phase_name = "SPIN ";
                default: phase_name = "---- ";
            endcase
        end
    endfunction

    // ====================================================
    // MAIN SIMULATION
    // ====================================================
    initial begin
        $display("========================================");
        $display("WASHING MACHINE SIMULATION STARTED");
        $display("========================================");

        rst_n = 0; start = 0; cancel = 0; lid = 0;
        mode1 = 0; mode2 = 0; mode3 = 0;
        #20 rst_n = 1;
        #50;

        // Select mode
        case (TEST_MODE)
            1: begin mode1=1; mode2=0; mode3=0; $display(">> QUICK WASH"); end
            2: begin mode1=0; mode2=1; mode3=0; $display(">> NORMAL WASH"); end
            3: begin mode1=0; mode2=0; mode3=1; $display(">> HEAVY WASH"); end
        endcase

        start = 1; #50; start = 0;

        $display("\nTime(s)   State   Phase    Timer     Timer_Done");
        $display("------------------------------------------------------");
        start_time = $time;

        while (state != 3'd0 || timer_enable == 1'b1) begin
            #50;
            $display("%-8d  %-6d  %-6s  %-8d  %-1b", 
                $time/100, state, phase_name(state), counter_out, timer_done);
        end

        end_time = $time;
        $display("\nWashing cycle completed at time %0d seconds", (end_time - start_time)/1000);
        $display("========================================\n");
        $finish;
    end
endmodule
