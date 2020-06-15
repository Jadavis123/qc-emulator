`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2020 10:23:38 AM
// Design Name: 
// Module Name: quantumCompFSM
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


module quantumCompFSM(
    input clk,
    input reset,
    input btnC,
    input RsRx,
    output RsTx
    );
    
    parameter N=2;
    parameter RESET = 3'b000;
    parameter LOAD_STATE_REAL = 3'b001;
    parameter LOAD_STATE_IMAG = 3'b010;
    parameter LOAD_GATE_REAL = 3'b011;
    parameter LOAD_GATE_IMAG = 3'b100;
    parameter CHECK_REPEAT = 3'b101;
    parameter SEND_STATE_REAL = 3'b110;
    parameter SEND_STATE_IMAG = 3'b111;
    
    bit load_ready;
    bit [7:0] new_gate;
    logic [7:0] send_temp, send_temp2, load_temp, load_temp2;
    logic [2:0] fState = RESET;
    
    int row, col;
    parameter max = 2**N;
    
    complexNum gate[max-1:0][max-1:0];
    complexNum state[max-1:0];
    complexNum outState[max-1:0];
    
    //module that generates structure of multipliers and adders to perform
    //gate*state operation
    gateStateMult #(N) myMult(
    clk,
    reset,
    state, //input state
    gate, //gate
    outState //output state
    );
    
    microblaze_mcs_0 your_instance_name (
    .Clk(clk),                        // input wire Clk
    .Reset(btnC),                    // input wire Reset
    .UART_rxd(RsRx),              // input wire UART_rxd
    .UART_txd(RsTx),              // output wire UART_txd
    .GPIO1_tri_i(send_temp),        // input wire [7 : 0] GPIO1_tri_i
    .GPIO2_tri_i(send_temp2),  // input wire [7 : 0] GPIO2_tri_i
    .GPIO1_tri_o(load_temp),        // output wire [7 : 0] GPIO1_tri_o
    .GPIO2_tri_o(load_ready),        // output wire [0 : 0] GPIO2_tri_o
    .GPIO3_tri_o(new_gate),  // output wire [7 : 0] GPIO3_tri_o
    .GPIO4_tri_o(load_temp2)  // output wire [7 : 0] GPIO4_tri_o
    );
    
    always @(posedge clk) begin
        case(fState)
            RESET: begin //set counters to 0 in case they haven't been already
                row <= 0;
                col <= 0;
                fState <= LOAD_STATE_REAL;
                end
            LOAD_STATE_REAL: begin
                //load 2 bytes into state once ready flag goes high
                if (load_ready) begin 
                    state[col].a[15:8] <= load_temp;
                    state[col].a[7:0] <= load_temp2;
                    fState <= LOAD_STATE_IMAG;
                    end
                else begin //otherwise, continue waiting for flag
                    fState <= LOAD_STATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            LOAD_STATE_IMAG: begin
                //load 2 bytes into state once ready flag goes low, update indices 
                //and state according to whether state is finished or not
                if (~load_ready) begin
                    if (col == max-1) begin
                        state[col].b[15:8] <= load_temp;
                        state[col].b[7:0] <= load_temp2;
                        col <= 0;
                        fState <= LOAD_GATE_REAL;
                        end
                    else begin
                        state[col].b[15:8] <= load_temp;
                        state[col].b[7:0] <= load_temp2;                        
                        col <= col+1;
                        fState <= LOAD_STATE_REAL;
                        end
                    end
                else begin
                    fState <= LOAD_STATE_IMAG;
                    col <= col;
                    end
                row <= row;
                end
            LOAD_GATE_REAL: begin
                if (load_ready) begin
                    gate[row][col].a[15:8] <= load_temp;
                    gate[row][col].a[7:0] <= load_temp2;
                    fState <= LOAD_GATE_IMAG;
                    end
                else begin
                    fState <= LOAD_GATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            LOAD_GATE_IMAG: begin
                if (~load_ready) begin
                    if (col == max-1) begin
                        if (row == max-1) begin
                            gate[row][col].b[15:8] <= load_temp;
                            gate[row][col].b[7:0] <= load_temp2;
                            row <= 0;
                            col <= 0;
                            fState <= CHECK_REPEAT;                           
                            end
                        else begin
                            gate[row][col].b[15:8] <= load_temp;
                            gate[row][col].b[7:0] <= load_temp2;
                            row <= row+1;
                            col <= 0;
                            fState <= LOAD_GATE_REAL;                            
                            end
                        end
                    else begin
                        gate[row][col].b[15:8] <= load_temp;
                        gate[row][col].b[7:0] <= load_temp2;
                        row <= row;
                        col <= col+1;
                        fState <= LOAD_GATE_REAL;                        
                        end
                    end
                else begin
                    fState <= LOAD_GATE_IMAG;                    
                    row <= row;
                    col <= col;
                    end
                end
            CHECK_REPEAT: begin
                //if final gate is not yet reached, go back to loading gate and 
                //use previous output state as new input state for next operation
                if (new_gate[0]) begin
                    state <= outState;
                    fState <= LOAD_GATE_REAL;
                    end
                //if final gate is reached, move forward to sending
                else begin
                    fState <= SEND_STATE_REAL;
                    end
                row <= 0;
                col <= 0;
                end
            SEND_STATE_REAL: begin
                if (load_ready) begin
                    send_temp <= outState[col].a[15:8];
                    send_temp2 <= outState[col].a[7:0];
                    fState <= SEND_STATE_IMAG;
                    end
                else begin
                    fState <= SEND_STATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            SEND_STATE_IMAG: begin
                if (~load_ready) begin
                    if (col == max-1) begin
                        send_temp <= outState[col].b[15:8];
                        send_temp2 <= outState[col].b[7:0];
                        col <= 0;
                        fState <= RESET;
                        end
                    else begin
                        send_temp <= outState[col].b[15:8];
                        send_temp2 <= outState[col].b[7:0];
                        col <= col+1;
                        fState <= SEND_STATE_REAL;
                        end
                    end
                else begin
                    fState <= SEND_STATE_IMAG;
                    col <= col;
                    end
                row <= row;
                end
        endcase
    end
    
endmodule
