`timescale 1ns / 1ps
module tb_washing_machine;

    // ============================================================
    // Signal Declarations
    // ============================================================
    reg clk, rst_n, start, cancel, lid, power_on;
    reg mode1, mode2, mode3, mode4;
    wire [2:0] state;
    wire [1:0] phase_sel;
    wire soak_en, wash_en, rinse_en, spin_en;
    wire timer_enable, timer_done;
    wire [31:0] counter_out;

    integer start_time, end_time;

    // ============================================================
    // Simulation Parameters
    // ============================================================
    parameter MODEL_SELECT = 1;   // 0 = Behavioral, 1 = Dataflow, 2 = Gate-level
    parameter TEST_MODE    = 1;   // 1 = Quick, 2 = Normal, 3 = Heavy, 4 = Spin-only

    // ============================================================
    // Clock Generation
    // ============================================================
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period

    // ============================================================
    // Timer Instantiation
    // ============================================================
    multi_phase_timer timer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(timer_enable),
        .phase_sel(phase_sel),
        .mode1(mode1),
        .mode2(mode2),
        .mode3(mode3),
        .mode4(mode4),
        .start(start),
        .power_on(power_on),
        .timer_done(timer_done),
        .counter_out(counter_out)
    );

    // ============================================================
    // FSM Model Instantiation (Selectable)
    // ============================================================
    generate
        if (MODEL_SELECT == 0) begin
            washing_machine_behavioral fsm_inst (
                .clk(clk),
                .rst_n(rst_n),
                .start(start),
                .cancel(cancel),
                .lid(lid),
                .mode1(mode1),
                .mode2(mode2),
                .mode3(mode3),
                .mode4(mode4),
                .timer_done(timer_done),
                .power_on(power_on),
                .state(state),
                .phase_sel(phase_sel),
                .soak_en(soak_en),
                .wash_en(wash_en),
                .rinse_en(rinse_en),
                .spin_en(spin_en),
                .timer_enable(timer_enable)
            );
        end
        else if (MODEL_SELECT == 1) begin
            washing_machine_dataflow fsm_inst (
                .clk(clk),
                .rst_n(rst_n),
                .start(start),
                .cancel(cancel),
                .lid(lid),
                .mode1(mode1),
                .mode2(mode2),
                .mode3(mode3),
                .mode4(mode4),
                .timer_done(timer_done),
                .power_on(power_on),
                .state(state),
                .phase_sel(phase_sel),
                .soak_en(soak_en),
                .wash_en(wash_en),
                .rinse_en(rinse_en),
                .spin_en(spin_en),
                .timer_enable(timer_enable)
            );
        end
        else begin
            washing_machine_gate fsm_inst (
                .clk(clk),
                .rst_n(rst_n),
                .start(start),
                .cancel(cancel),
                .lid(lid),
                .mode1(mode1),
                .mode2(mode2),
                .mode3(mode3),
                .mode4(mode4),
                .timer_done(timer_done),
                .power_on(power_on),
                .state(state),
                .phase_sel(phase_sel),
                .soak_en(soak_en),
                .wash_en(wash_en),
                .rinse_en(rinse_en),
                .spin_en(spin_en),
                .timer_enable(timer_enable)
            );
        end
    endgenerate

    // ============================================================
    // Phase Name Helper Function
    // ============================================================
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

    // ============================================================
    // Main Testbench Logic
    // ============================================================
    initial begin
        $display("========================================");
        $display("     WASHING MACHINE SIMULATION STARTED ");
        $display("========================================");

        // Initial conditions
        rst_n = 0;
        start = 0;
        cancel = 0;
        lid = 0;
        power_on = 1;
        mode1 = 0;
        mode2 = 0;
        mode3 = 0;
        mode4 = 0;

        // Reset sequence
        #20 rst_n = 1;
        #50;

        // Select mode
        case (TEST_MODE)
            1: begin mode1 = 1; $display(">> QUICK WASH MODE SELECTED"); end
            2: begin mode2 = 1; $display(">> NORMAL WASH MODE SELECTED"); end
            3: begin mode3 = 1; $display(">> HEAVY WASH MODE SELECTED"); end
            4: begin mode4 = 1; $display(">> SPIN-ONLY MODE SELECTED"); end
        endcase

        // Start washing machine
        start = 1; #50; start = 0;

        $display("\nTime(s)   State   Phase    Timer     Power");
        $display("------------------------------------------------------");

        start_time = $time;

        // Power cut simulation in parallel
        fork
            begin : monitor_loop
                while (state != 3'd0 || timer_enable == 1'b1) begin
                    #50;
                    $display("%-8d  %-6d  %-6s  %-8d  %-1b",
                        $time/100, state, phase_name(state),
                        counter_out, power_on);
                end
            end

            begin : power_cut_simulation
                #400 power_on = 0;
                $display(">>> POWER OFF at %0t ns", $time);
                #300 power_on = 1;
                $display(">>> POWER ON again at %0t ns", $time);
            end
        join

        end_time = $time;
        $display("\nWashing cycle completed at time %0d seconds", (end_time - start_time)/1000);
        $display("========================================");
        $finish;
    end

endmodule
