`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2020 02:43:30 PM
// Design Name: 
// Module Name: fixedPtTest
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


module fixedPtTest(
    input btnC,
    input clk,
    input [15:0] sw,
    output [3:0] an,
    output [6:0] seg,
    output [15:0] led
    );
    
    wire[7:0] A, B, C;
    wire overflow;
    assign B = sw[7:0];
    assign A = sw[15:8];
    
    qmult #(6,8) my_mult(
        A,
        B,
        C,
        overflow
        );
    
    HexDisplayV2 HexInst0(
    clk,
    C,
    ~btnC,
    1'b1,
    seg,
    an
    );
    
    assign led = sw;
endmodule
