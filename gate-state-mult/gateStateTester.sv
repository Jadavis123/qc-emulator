`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2020 10:40:44 AM
// Design Name: 
// Module Name: gateStateTester
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
//typedef struct{
//    bit [7:0] a;
//    bit [7:0] b;
//    }complexNum;

module gateStateTester(
    input clk,
    input reset,
    output [15:0] led
    );
    
    complexNum zero = '{8'b00000000, 8'b00000000};
    complexNum one = '{8'b01000000, 8'b00000000};
    complexNum ptFive = '{8'b00100000, 8'b00000000};
    complexNum ptFivei = '{8'b00100000, 8'b00100000};
    complexNum ptFiveNegi = '{8'b00100000, 8'b10100000};
    
    complexNum state[1:0] = '{zero, ptFivei};
    complexNum gate[1:0][1:0] = '{'{zero, ptFiveNegi}, '{zero, ptFivei}};
    complexNum outState[1:0];
    
    gateStateMult #(1) mult(
        clk,
        reset,
        state,
        gate,
        outState
        );
        
    assign led[15:8] = outState[0].a;
    assign led[7:0] = outState[0].b;
    
endmodule
