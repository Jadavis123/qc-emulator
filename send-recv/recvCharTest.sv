`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 10:23:45 AM
// Design Name: 
// Module Name: recvCharTest
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


module recvCharTest(
    input clk,
    input btnC,
    input RsRx,
    output RsTx,
    input [7:0] sw,
    output [7:0] led
    );
    
    microblaze_mcs_0 mcs_0 (
    .Clk(clk),                  // input wire Clk
    .Reset(btnC),              // input wire Reset
    .UART_rxd(RsRx),        // input wire UART_rxd
    .UART_txd(RsTx),        // output wire UART_txd
    .GPIO1_tri_i(sw),  // input wire [7 : 0] GPIO1_tri_i
    .GPIO1_tri_o(led)  // output wire [7 : 0] GPIO1_tri_o
    );
    
endmodule
