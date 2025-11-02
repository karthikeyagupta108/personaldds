`timescale 1ns/1ps
module washing_machine_behavioral(
    input  wire clk, rst_n, start, cancel, lid,
    input  wire mode1, mode2, mode3, mode4,
    input  wire timer_done, power_on,
    output reg  [2:0] state,
    output reg  [1:0] phase_sel,
    output reg  soak_en, wash_en, rinse_en, spin_en,
    output reg  timer_enable
);
    localparam IDLE=3'd0, READY=3'd1, SOAK=3'd2,
               WASH=3'd3, RINSE=3'd4, SPIN=3'd5;

    reg [2:0] next_state;
    reg start_latched;
    reg [3:0] mode_latched;

    // latch start + mode
    always @(posedge clk or negedge rst_n)
        if(!rst_n) begin start_latched<=0; mode_latched<=0; end
        else if(start && state==IDLE) begin start_latched<=1; mode_latched<={mode1,mode2,mode3,mode4}; end
        else if(state!=IDLE && next_state==IDLE) start_latched<=0;

    // sequential logic with power freeze
    always @(posedge clk or negedge rst_n)
        if(!rst_n) state<=IDLE;
        else if(power_on) state<=next_state;
        else state<=state;

    // next state logic
    always @(*) begin
        next_state=state; phase_sel=2'b00; timer_enable=0;
        case(state)
            IDLE:  if(lid==0 && start_latched && !cancel) next_state=READY;
            READY: if(lid==0 && !cancel && mode_latched!=0)
                        next_state=(mode4)?SPIN:SOAK;
                   else if(cancel) next_state=IDLE;
            SOAK:  begin phase_sel=2'b00; timer_enable=1;
                   if(!cancel && timer_done) next_state=WASH;
                   else if(cancel) next_state=IDLE; end
            WASH:  begin phase_sel=2'b01; timer_enable=1;
                   if(!cancel && timer_done) next_state=RINSE;
                   else if(cancel) next_state=IDLE; end
            RINSE: begin phase_sel=2'b10; timer_enable=1;
                   if(!cancel && timer_done) next_state=SPIN;
                   else if(cancel) next_state=IDLE; end
            SPIN:  begin phase_sel=2'b11; timer_enable=1;
                   if(!cancel && timer_done) next_state=IDLE;
                   else if(cancel) next_state=IDLE; end
        endcase
    end

    always @(posedge clk or negedge rst_n)
        if(!rst_n) {soak_en,wash_en,rinse_en,spin_en}<=0;
        else begin
            soak_en <= (state==SOAK);
            wash_en <= (state==WASH);
            rinse_en<= (state==RINSE);
            spin_en <= (state==SPIN);
        end
endmodule
