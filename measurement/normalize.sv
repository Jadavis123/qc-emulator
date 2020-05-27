`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2020 09:54:20 AM
// Design Name: 
// Module Name: normalize
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

typedef struct packed{
    bit[7:0] a;
    bit[7:0] b;
    }complexNum;
    
typedef struct packed{
    bit[7:0] aa;
    bit[7:0] bb;
    bit[7:0] sum;
    }sumStore;

module normalize #(int N=1)(
    input clk,
    input complexNum[(2**N)-1:0] state,
    output complexNum[(2**N)-1:0] outState
    );
    
    sumStore[(2**N)-1:0] temp;
    bit[7:0] tempSum[(2**N)-2:0];
    bit overflow, complete;
    genvar i, j, k, l;
    generate
    for (i = 0; i < 2**N; i = i+1)begin:gen1
        qmult #(6,8) multA(state[i].a, state[i].a, temp[i].aa, overflow);
        qmult #(6,8) multB(state[i].b, state[i].b, temp[i].bb, overflow);
        qadd #(6,8) add(temp[i].aa, temp[i].bb, temp[i].sum);
    end
    for (j = 0; j < 2**(N-1); j = j+1)begin:gen2
        qadd #(6,8) add(temp[2*j].sum, temp[2*j+1].sum, tempSum[j]);
    end
    for (k = 0; k < (2**(N-1))-1; k = k+1)begin:gen3
        qadd #(6,8) add(tempSum[2*k], tempSum[2*k+1], tempSum[(2**(N-1))+k]);
    end
    for (l = 0; l < 2**N; l = l+1) begin:gen4
        qdiv #(6,8) divRe(state[l].a, tempSum[(2**N)-2], 1'b1, clk, outState[l].a, complete, overflow);
        qdiv #(6,8) divIm(state[l].b, tempSum[(2**N)-2], 1'b1, clk, outState[l].b, complete, overflow);
    end
    endgenerate
endmodule
