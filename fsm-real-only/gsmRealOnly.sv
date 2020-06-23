`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2020 09:34:47 AM
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

module gsmRealOnly #(int N=2)(
        input clk,
        input reset,
        input  logic [15:0] state[(2**N)-1:0],
        input logic [15:0] gate[(2**N)-1:0][(2**N)-1:0],
        output logic [15:0] outState[(2**N)-1:0]
    );
    
    //matrices to store temporary products and sums, since we can only multiply/add 2 at a time
    logic [15:0] temp [(2**N)-1:0][(2**(N+1))-3:0];
    logic overflow;
    genvar row, col, i;
    //Generates a qmult module for each gate matrix element and its corresponding state vector 
    //element, then adds them all up in binary tree structure
    generate
    for (row = 0; row < 2**N; row=row+1) begin:gen1
    for (col = 0; col < 2**N; col=col+1) begin:gen2
        //first two 'arguments' in qmult are multiplicands, third is product, fourth is overflow
        qmult #(14, 16) mult1(gate[row][col], state[col], temp[row][col], overflow);
    end
    //generate "binary tree" of adders to find total real and imag components:
    //since we know there are 2^N terms to add up for each row, we can break this down into
    //2^(N-1) adders, then 2^(N-2) adding up their sums, etc. until only one sum remains
    //e.g. for 3 qubits (8 terms) we would have: 1+2, 3+4, 5+6, 7+8, then (1+2) + (3+4) and
    //(5+6) + (7+8), and finally (1+2+3+4) + (5+6+7+8) is our sum
    for (i=0; i < (2**N)-2; i=i+1) begin:gen3
        qadd #(14, 16) addRe(temp[row][2*i], temp[row][(2*i)+1], temp[row][(2**N)+i]);
    end
    qadd #(14, 16) addFinalRe(temp[row][(2**(N+1))-4], temp[row][(2**(N+1))-3], outState[row]);
    end
    endgenerate
    
endmodule