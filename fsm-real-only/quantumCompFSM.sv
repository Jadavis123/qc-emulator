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


module qcFSMRealOnly(
    input clk, //clock needed for always block
    input reset, //reset button, resets FPGA to default programming
    input btnC, //reset button for MicroBlaze
    input RsRx, //UART receiving line
    output RsTx //UART transmission line
    );
    
    parameter N=3; //number of qubits - currently 2 is the max that fits on this FPGA
    //Various states for finite state machine are defined here
    parameter RESET = 3'b000;
    parameter LOAD_STATE_REAL = 3'b001;
    parameter LOAD_STATE_WAIT = 3'b010;
    parameter LOAD_GATE_REAL = 3'b011;
    parameter LOAD_GATE_WAIT = 3'b100;
    parameter CHECK_REPEAT = 3'b101;
    parameter SEND_STATE_REAL = 3'b110;
    parameter SEND_STATE_WAIT = 3'b111;
    
    bit load_ready; //flag that flips whenever the MicroBlaze receives a new number for the FPGA
    bit [7:0] new_gate; //0th bit is flag that temporarily goes high when there is a new gate
    logic [7:0] send_temp, send_temp2, load_temp, load_temp2; //temporary storage variables
    logic [2:0] fState = RESET; //initial state
    
    int row, col; //indices for moving through state/gate
    parameter max = 2**N; //length of state vector (2^N) and each side of gate matrix
    
    logic [15:0] gate[max-1:0][max-1:0]; //2^N * 2^N matrix to store current gate
    logic [15:0] state[max-1:0]; //2^N * 1 array to store current state
    logic [15:0] outState[max-1:0]; //2^N * 1 array to store output state
    
    //multiplier module that only works if gates and states are entirely real
    gsmRealOnly #(N) myMultReal(
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
    
    ///////////////////////////////////////////////////////////////////////////////////
    //Finite State Machine - starts in RESET state and follows conditional logic checks
    //Starts in RESET state - sets counters to 0 and moves to LOAD_STATE_REAL
    //
    //LOAD_STATE_REAL - waits for load_ready flag to go high, then loads num into real
    //component of current index of state. Then moves to LOAD_STATE_IMAG.
    //
    //LOAD_STATE_IMAG - waits for load_ready flag to go low, then loads num into imag
    //component of current index of state. If index is at max-1, the state is finished
    //loading, so moves to LOAD_GATE_REAL and resets counters. If index is not yet at
    //max-1, state is not finished, so increases index by one and goes back to 
    //LOAD_STATE_REAL
    //
    //LOAD_GATE_REAL - similar to LOAD_STATE_REAL, waits for load_ready to go high,
    //then loads num into real part of appropriate position in gate (row, col) and
    //moves to LOAD_GATE_IMAG
    //
    //LOAD_GATE_IMAG - waits for load_ready to go low, then loads num into imag part of
    //appropriate position in gate. If it has reached the end of the gate (both row and
    //col are at max-1), it resets counters and moves to CHECK_REPEAT. If it has
    //reached the end of a row but not the last row, it resets col to 0 and adds 1 to
    //row, then goes back to LOAD_GATE_REAL. If it has not yet reached the end of a row,
    //it adds 1 to col and keeps row the same, then goes back to LOAD_GATE_REAL
    //
    //CHECK_REPEAT - once a gate is finished loading, reads the 0th bit of the new_gate
    //flag. If it is high, there is a new gate coming in that is now operating on the 
    //output state of the previous operation, thus we load the current outState into
    //state and move back to LOAD_GATE_REAL with indices reset. If it is low, there is
    //no new gate, so it moves to SEND_STATE_REAL
    //
    //SEND_STATE_REAL - works in the same way as LOAD_STATE_REAL, except now sends real
    //part of current num to MicroBlaze so it can send it to the PC and moves to
    //SEND_STATE_IMAG
    //
    //SEND_STATE_IMAG - works in the same way as LOAD_STATE_IMAG, except now sends imag
    //part of current num to MicroBlaze. When it is finished, it goes back to RESET,
    //which then goes to LOAD_GATE_REAL to await the next state/gates sent by the PC
    ///////////////////////////////////////////////////////////////////////////////////
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
                    state[col][15:8] <= load_temp;
                    state[col][7:0] <= load_temp2;
                    fState <= LOAD_STATE_WAIT;
                    end
                else begin //otherwise, continue waiting for flag
                    fState <= LOAD_STATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            LOAD_STATE_WAIT: begin
                //load 2 bytes into state once ready flag goes low, update indices 
                //and state according to whether state is finished or not
                if (~load_ready) begin
                    if (col == max-1) begin
                        col <= 0;
                        fState <= LOAD_GATE_REAL;
                        end
                    else begin                  
                        col <= col+1;
                        fState <= LOAD_STATE_REAL;
                        end
                    end
                else begin
                    fState <= LOAD_STATE_WAIT;
                    col <= col;
                    end
                row <= row;
                end
            LOAD_GATE_REAL: begin
                if (load_ready) begin
                    gate[row][col][15:8] <= load_temp;
                    gate[row][col][7:0] <= load_temp2;
                    fState <= LOAD_GATE_WAIT;
                    end
                else begin
                    fState <= LOAD_GATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            LOAD_GATE_WAIT: begin
                if (~load_ready) begin
                    if (col == max-1) begin
                        if (row == max-1) begin
                            row <= 0;
                            col <= 0;
                            fState <= CHECK_REPEAT;                           
                            end
                        else begin
                            row <= row+1;
                            col <= 0;
                            fState <= LOAD_GATE_REAL;                            
                            end
                        end
                    else begin
                        row <= row;
                        col <= col+1;
                        fState <= LOAD_GATE_REAL;                        
                        end
                    end
                else begin
                    fState <= LOAD_GATE_WAIT;                    
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
                    send_temp <= outState[col][15:8];
                    send_temp2 <= outState[col][7:0];
                    fState <= SEND_STATE_WAIT;
                    end
                else begin
                    fState <= SEND_STATE_REAL;
                    end
                row <= row;
                col <= col;
                end
            SEND_STATE_WAIT: begin
                if (~load_ready) begin
                    if (col == max-1) begin
                        col <= 0;
                        fState <= RESET;
                        end
                    else begin
                        col <= col+1;
                        fState <= SEND_STATE_REAL;
                        end
                    end
                else begin
                    fState <= SEND_STATE_WAIT;
                    col <= col;
                    end
                row <= row;
                end
        endcase
    end
    
endmodule
