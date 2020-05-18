`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2020 02:48:38 PM
// Design Name: 
// Module Name: microblazeTester
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


module microblazeTester(
    input clk,
    input RsRx,
    input btnC,
    input btnR,
    output RsTx,
    input [7:0] sw
    );
    
    microblaze_mcs_0 mcs_0 (
    .Clk(clk),                        // input wire Clk
    .Reset(btnC),                    // input wire Reset
    .GPI1_Interrupt(),  // output wire GPI1_Interrupt
    .INTC_IRQ(),              // output wire INTC_IRQ
    .UART_rxd(RsRx),              // input wire UART_rxd
    .UART_txd(RsTx),              // output wire UART_txd
    .GPIO1_tri_i(btnR),        // input wire [0 : 0] GPIO1_tri_i
    .GPIO2_tri_i(sw)        // input wire [7 : 0] GPIO2_tri_i
    );
endmodule
