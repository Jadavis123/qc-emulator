`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2020 01:28:51 PM
// Design Name: 
// Module Name: matrixVectorMult
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

//Multiplies a gate matrix by a state vector for a given fixed-point number size (default is 8 for SIFFFFFF format) and # qubits (default is 3)
module matrixVectorMult #(int SIZE = 8, N=3)(
        input clk,
        input reset,
        input [SIZE-1:0] state[(2^N)-1:0],
        input [SIZE-1:0] gate[(2^N)-1:0][(2^N)-1:0],
        output [SIZE-1:0] outState[(2^N)-1:0]
    );
    
    //Makes an extra large matrix to temporarily store outputs of qmult/qadd modules 
    logic [SIZE-1:0] temp [(2^N)-1:0][(2^(N+1))-3:0];
    logic overflow;
    genvar row, col, i;
    //Generates a qmult module for each gate matrix element and its corresponding state vector element, then adds them all up in binary tree structure
    generate
    for (row = 0; row < 2^N; row=row+1) begin:gen1
    for (col = 0; col < 2^N; col=col+1) begin:gen2
        qmult #(SIZE-2, SIZE) mult(gate[row][col], state[col], temp[row][col], overflow);
    end
    for (i=0; i < (2^N)-2; i=i+1) begin:gen3
            qadd #(SIZE-2, SIZE) add(temp[row][2*i], temp[row][(2*i)+1], temp[row][(2^N)+i], overflow);
    end
    qadd #(SIZE-2, SIZE) addFinal(temp[row][(2^(N+1))-4], temp[row][(2^(N+1))-3], outState[row], overflow);
    end
    endgenerate
    
endmodule
