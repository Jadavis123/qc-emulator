`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2020 04:47:13 PM
// Design Name: 
// Module Name: arrayTester
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module arrayTester(
    input btnC,
    input btnR,
    input clk,
    input [15:0] sw,
    output [3:0] an,
    output [6:0] seg,
    output RsTx
    );
    
    logic[7:0] out1, out2, out3;
    logic overflow, reset;
    
    typedef struct {
    logic[7:0] a;
    logic[7:0] b;
    } complexNum;
    
    complexNum state [1:0];
    
    assign state[0].a = sw[15:8];
    assign state[0].b = sw[7:0];
    assign state[1].a = sw[15:8];
    assign state[1].b = sw[7:0];
    
    qmult #(6,8) mult1(
        state[0].a,
        state[1].a,
        out1,
        overflow
        );
        
    qmult #(6,8) mult2(
        state[0].b,
        state[1].b,
        out2,
        overflow
        );
        
    qadd #(6,8) adder(
        out1,
        out2,
        out3
        );
        
    HexDisplayV2 HexInst0(
    clk,
    out3,
    ~btnC,
    1'b1,
    seg,
    an
    );
    
    microblaze_mcs_0 mcs_0 (
    .Clk(clk),                        // input wire Clk
    .Reset(reset),                    // input wire Reset
    .GPI1_Interrupt(),  // output wire GPI1_Interrupt
    .INTC_IRQ(),              // output wire INTC_IRQ
    .UART_txd(RsTx),              // output wire UART_txd
    .GPIO1_tri_i(btnR),        // input wire [0 : 0] GPIO1_tri_i
    .GPIO2_tri_i(out3)        // input wire [7 : 0] GPIO2_tri_i
    );
    
endmodule
