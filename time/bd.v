`timescale 1ns/1ps
module washing_machine_dataflow(
    input  wire clk, rst_n, start, cancel, lid,
    input  wire mode1, mode2, mode3, mode4,
    input  wire timer_done, power_on,
    output reg  [2:0] state,
    output wire [1:0] phase_sel,
    output wire soak_en, wash_en, rinse_en, spin_en,
    output wire timer_enable
);
    localparam IDLE=3'd0, READY=3'd1, SOAK=3'd2,
               WASH=3'd3, RINSE=3'd4, SPIN=3'd5;

    reg [2:0] next_state;
    wire [3:0] mode_sel = {mode1,mode2,mode3,mode4};

    // next-state combinational logic
    always @(*) begin
        case(state)
            IDLE:  next_state = (lid==0 && start && !cancel)? READY: IDLE;
            READY: next_state = (cancel)? IDLE :
                                (mode4)? SPIN :
                                (lid==0 && mode_sel!=0)? SOAK : READY;
            SOAK:  next_state = (cancel)? IDLE :
                                (timer_done)? WASH : SOAK;
            WASH:  next_state = (cancel)? IDLE :
                                (timer_done)? RINSE : WASH;
            RINSE: next_state = (cancel)? IDLE :
                                (timer_done)? SPIN : RINSE;
            SPIN:  next_state = (cancel)? IDLE :
                                (timer_done)? IDLE : SPIN;
            default: next_state = IDLE;
        endcase
    end

    // sequential with power hold
    always @(posedge clk or negedge rst_n)
        if(!rst_n) state<=IDLE;
        else if(power_on) state<=next_state;
        else state<=state;

    // dataflow outputs
    assign phase_sel =
        (state==SOAK)? 2'b00 :
        (state==WASH)? 2'b01 :
        (state==RINSE)?2'b10 :
        (state==SPIN)? 2'b11 : 2'b00;

    assign timer_enable = (state!=IDLE && state!=READY);

    assign soak_en  = (state==SOAK);
    assign wash_en  = (state==WASH);
    assign rinse_en = (state==RINSE);
    assign spin_en  = (state==SPIN);
endmodule
