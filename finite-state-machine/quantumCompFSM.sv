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
    output RsTx,
    output [7:0] led
    );
    
    parameter N=2;
    parameter RESET = 3'b000;
    parameter LOAD_STATE_REAL = 3'b001;
    parameter LOAD_STATE_IMAG = 3'b010;
    parameter LOAD_GATE_REAL = 3'b011;
    parameter LOAD_GATE_IMAG = 3'b100;
    parameter SEND_STATE_REAL = 3'b101;
    parameter SEND_STATE_IMAG = 3'b110;
    
    logic load_ready;
    logic [7:0] send_temp, load_temp;
    logic [2:0] fState = RESET;
    
    int row, col;
    parameter max = 2**N;
    
    complexNum gate[max-1:0][max-1:0];
    complexNum state[max-1:0];
    complexNum outState[max-1:0];
    
    gateStateMult #(N) myMult(
    clk,
    reset,
    state,
    gate,
    outState
    );
    
    microblaze_mcs_0 your_instance_name (
    .Clk(clk),                        // input wire Clk
    .Reset(btnC),                    // input wire Reset
    .UART_rxd(RsRx),              // input wire UART_rxd
    .UART_txd(RsTx),              // output wire UART_txd
    .GPIO1_tri_i(send_temp),        // input wire [7 : 0] GPIO1_tri_i
    .GPIO1_tri_o(load_temp),        // output wire [7 : 0] GPIO1_tri_o
    .GPIO2_tri_o(load_ready)        // output wire [0 : 0] GPIO2_tri_o
    );
    
    assign led = outState[2].a;
    
    always @(posedge clk) begin
        case(fState)
            RESET: begin
                row <= 0;
                col <= 0;
                fState <= LOAD_STATE_REAL;
                end
            LOAD_STATE_REAL: begin
                if (load_ready) begin
                    state[col].a <= load_temp;
                    fState <= LOAD_STATE_IMAG;
                    end
                else begin
                    fState <= LOAD_STATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            LOAD_STATE_IMAG: begin
                if (~load_ready) begin
                    if (col == max-1) begin
                        state[col].b <= load_temp;
                        col <= 0;
                        fState <= LOAD_GATE_REAL;
                        end
                    else begin
                        state[col].b <= load_temp;
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
                    gate[row][col].a <= load_temp;
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
                        gate[row][col].b <= load_temp;
                            row <= 0;
                            col <= 0;
                            fState <= SEND_STATE_REAL;                           
                            end
                        else begin
                            gate[row][col].b <= load_temp;
                            row <= row+1;
                            col <= 0;
                            fState <= LOAD_GATE_REAL;                            
                            end
                        end
                    else begin
                        gate[row][col].b <= load_temp;
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
            SEND_STATE_REAL: begin
                if (load_ready) begin
                    send_temp <= outState[col].a;
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
                        send_temp <= outState[col].b;
                        col <= 0;
                        fState <= RESET;
                        end
                    else begin
                        send_temp <= outState[col].b;
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
