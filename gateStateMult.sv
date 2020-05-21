`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2020 03:49:21 PM
// Design Name: 
// Module Name: gateStateMult
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

typedef struct{
    logic [7:0] a;
    logic [7:0] b;
    }complexNum;
    
typedef struct{
    logic [7:0] a;
    logic [7:0] ab;
    logic[7:0] ba;
    logic[7:0]b;
    }compNumTemp;

module gateStateMult #(int N=3)(
        input clk,
        input reset,
        input  complexNum state[(2^N)-1:0],
        input complexNum gate[(2^N)-1:0][(2^N)-1:0],
        output complexNum outState[(2^N)-1:0]
    );
    
    //Makes an extra large matrix to temporarily store outputs of qmult/qadd modules 
    compNumTemp temp [(2^N)-1:0][(2^(N+1))-3:0];
    logic overflow;
    genvar row, col, i;
    //Generates a qmult module for each gate matrix element and its corresponding state vector element, then adds them all up in binary tree structure
    generate
    for (row = 0; row < 2^N; row=row+1) begin:gen1
    for (col = 0; col < 2^N; col=col+1) begin:gen2
        qmult #(6, 8) mult(gate[row][col].a, state[col].a, temp[row][col].a, overflow);
        qmult #(6, 8) mult1(gate[row][col].a, state[col].b, temp[row][col].ab, overflow);
        qmult #(6, 8) mult2(gate[row][col].b, state[col].a, temp[row][col].ba, overflow);
        qmult #(6, 8) mult3(gate[row][col].b, state[col].b, temp[row][col].b, overflow);
    end
    for (i=0; i < (2^N)-2; i=i+1) begin:gen3
        qadd #(6, 8) add(temp[row][2*i], temp[row][(2*i)+1], temp[row][(2^N)+i], overflow);
    end
        qadd #(6, 8) addFinal(temp[row][(2^(N+1))-4], temp[row][(2^(N+1))-3], outState[row], overflow);
    end
    endgenerate
    
endmodule