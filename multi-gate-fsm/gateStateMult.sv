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

//data type to store complex nums
typedef struct{
    logic [15:0] a;
    logic [15:0] b;
    }complexNum;
    
//data type to store outputs of multiplying 2 complex nums
typedef struct{
    logic [15:0] a;
    logic [15:0] ab;
    logic[15:0] ba;
    logic[15:0]b;
	logic[15:0]negB;
    }compNumTemp;

module gateStateMult #(int N=2)(
        input clk,
        input reset,
        input  complexNum state[(2**N)-1:0],
        input complexNum gate[(2**N)-1:0][(2**N)-1:0],
        output complexNum outState[(2**N)-1:0]
    );
    
    compNumTemp temp1 [(2**N)-1:0][(2**(N+1))-3:0];
	//Makes an extra large matrix to temporarily store outputs of qmult/qadd modules 
    complexNum temp2 [(2**N)-1:0][(2**(N+1))-3:0];
    logic overflow;
    genvar row, col, i;
    //Generates a qmult module for each gate matrix element and its corresponding state vector element, then adds them all up in binary tree structure
    generate
    for (row = 0; row < 2**N; row=row+1) begin:gen1
    for (col = 0; col < 2**N; col=col+1) begin:gen2
        //4 multipliers corresponding to FOILing 2 complex nums
        qmult #(14, 16) mult1(gate[row][col].a, state[col].a, temp1[row][col].a, overflow);
        qmult #(14, 16) mult2(gate[row][col].a, state[col].b, temp1[row][col].ab, overflow);
        qmult #(14, 16) mult3(gate[row][col].b, state[col].a, temp1[row][col].ba, overflow);
        qmult #(14, 16) mult4(gate[row][col].b, state[col].b, temp1[row][col].b, overflow);
		//create negative copy of b^2 for addition because of i^2
		assign temp1[row][col].negB[15] = ~temp1[row][col].b[15];
		assign temp1[row][col].negB[14:0] = temp1[row][col].b[14:0];
		//add real components
		qadd #(14, 16) add1(temp1[row][col].a, temp1[row][col].negB, temp2[row][col].a);
		//add imag components
		qadd #(14, 16) add2(temp1[row][col].ab, temp1[row][col].ba, temp2[row][col].b);	
    end
    //generate "binary tree" of adders to find total real and imag components
    for (i=0; i < (2**N)-2; i=i+1) begin:gen3
        qadd #(14, 16) addRe(temp2[row][2*i].a, temp2[row][(2*i)+1].a, temp2[row][(2**N)+i].a);
		qadd #(14, 16) addIm(temp2[row][2*i].b, temp2[row][(2*i)+1].b, temp2[row][(2**N)+i].b);
    end
    qadd #(14, 16) addFinalRe(temp2[row][(2**(N+1))-4].a, temp2[row][(2**(N+1))-3].a, outState[row].a);
	qadd #(14, 16) addFinalIm(temp2[row][(2**(N+1))-4].b, temp2[row][(2**(N+1))-3].b, outState[row].b);
    end
    endgenerate
    
endmodule