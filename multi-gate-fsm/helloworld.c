/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiomodule.h"
#include <stdbool.h>

//Quantum Computer Finite State Machine - MicroBlaze code  (115200 baud)

//The MicroBlaze acts as an intermediate step between the PC and the FPGA that can communicate
//with each, since they can't directly communicate with each other. Its only task is receiving
//numbers (already converted into the proper 2-byte format) from the PC and writing them to an
//output channel that the FPGA can read, then when all the receiving is done, read numbers from
//an input channel that the FPGA can access and send them to the PC by printing them to the
//serial console. It also has to handle the flag that tells the FPGA when to load/send new numbers
//since the FPGA is running on a much faster clock (100 MHz = 10 ns per cycle vs. 115200 baud =
//14400 bytes per second = 70 us per cycle).

int main()
{
init_platform();
int count = 0;
int gateCount = 0;
int numQ = 3; //number of qubits
int numState = (1 << numQ); //# elements in state - 1<<numQ is equivalent to 2^numQ, but simpler
int numGate = numState * numState; //# elements in gate
u32 data; //temp variable to read number from FPGA
XIOModule iomodule;
u8 rx_buf[10]; //u8 buffer to store received bytes
u8 next_flag[10]; //u8 buffer to store gate_next flag
u32 temp, temp3; //temp variables to convert received u8 into writable u32
u8 temp2; //temp variable to convert u32 from FPGA to u8, printable as char
u32 high = 1;
u32 low = 0;
bool gate_next;

//Set up XIOModule on MicroBlaze for communication with PC
data = XIOModule_Initialize(&iomodule, XPAR_IOMODULE_0_DEVICE_ID);
data = XIOModule_Start(&iomodule);

while(1){
	//Loop for receiving state
	while(count < numState)
	{
		//The Python program is going to be sending 2 bytes per number, and 2 numbers per
		//complex probability amplitude, so for each element in the state, we have to receive
		//4 bytes. The 4 while loops are not actually doing anything (note the semicolon right
		//after them instead of curly braces) other than waiting for the XIOModule_Recv function
		//to receive a byte, at which point it will store the byte in rx_buf[0] and return 1,
		//ending the loop. The byte is then converted into a u32 so it can be written to the FPGA.
		//After receiving the 2 real bytes, it sets the load_ready output flag high so that the
		//FPGA knows to read off the 2 bytes and load them into the state. The 2 imaginary bytes
		//work the same way, except that it writes the flag low afterwards so that the FPGA can
		//detect a change in the flag.

		while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0); //wait to receive first byte of real
		temp = rx_buf[0]; //convert byte to u32
		XIOModule_DiscreteWrite(&iomodule, 1, temp); //write input to 8-bit output
		while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0); //wait to receive second byte of real
		temp3 = rx_buf[0];
		XIOModule_DiscreteWrite(&iomodule, 4, temp3);
		XIOModule_DiscreteWrite(&iomodule, 2, high); //set the output flag high
		while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0); //wait to receive first byte of imag
		temp = rx_buf[0];
		XIOModule_DiscreteWrite(&iomodule, 1, temp);
		while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0); //wait to receive second byte of imag
		temp3 = rx_buf[0];
		XIOModule_DiscreteWrite(&iomodule, 4, temp3);
		XIOModule_DiscreteWrite(&iomodule, 2, low); //set the output flag low
		count++;
	}

	count = 0;

	gate_next = true;
	//Loop for continually receiving gates until finished
	while(gate_next)
	{
		//Before each gate, the Python program will either send a byte containing the value 0,
		//indicating that there are no more gates coming in, or 1, indicating that there is
		//another gate. If it is 0, it sets the gate_next bool to false so that the outer loop
		//will end. Otherwise, loading the numbers in the gates occurs in the same way as it does
		//for the state.

		while (XIOModule_Recv(&iomodule, next_flag, 1) == 0);
		if (next_flag[0] == 0)
		{
			gate_next = false; //end loop when last gate is reached
		}
		temp = next_flag[0];
		XIOModule_DiscreteWrite(&iomodule, 3, temp); //write gate_next as flag for FPGA
		while(count < numGate)
		{
			while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0);
			temp = rx_buf[0];
			XIOModule_DiscreteWrite(&iomodule, 1, temp);
			while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0);
			temp3 = rx_buf[0];
			XIOModule_DiscreteWrite(&iomodule, 4, temp3);
			XIOModule_DiscreteWrite(&iomodule, 2, high); //set the output flag high
			while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0);
			temp = rx_buf[0];
			XIOModule_DiscreteWrite(&iomodule, 1, temp);
			while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0);
			temp3 = rx_buf[0];
			XIOModule_DiscreteWrite(&iomodule, 4, temp3);
			XIOModule_DiscreteWrite(&iomodule, 2, low); //set the output flag low
			count++;
		}
		count = 0;
		gateCount++;
	}

	gateCount = 0;

	//Loop for sending out state
	while(count < numState){
		//Now we must write the bytes coming out of the FPGA as chars (the Python program reads
		//them as ints, and then converts them to the appropriate fixed point number). This is
		//essentially the reverse of the above process for receiving the state. However, this time
		//we must set the flag before reading each num instead of after, since the FPGA has to
		//know to load the bytes before the MicroBlaze tries to read them.

		XIOModule_DiscreteWrite(&iomodule, 2, high); //set flag high
		data = XIOModule_DiscreteRead(&iomodule, 1); //read first byte of real as u32
		temp2 = data; //convert u32 to u8 for printing as a char
		xil_printf("%c\n\r", temp2); //print byte as char
		data = XIOModule_DiscreteRead(&iomodule, 2); //read second byte of real
		temp2 = data;
		xil_printf("%c\n\r", temp2);
		XIOModule_DiscreteWrite(&iomodule, 2, low); //set flag low
		data = XIOModule_DiscreteRead(&iomodule, 1); //read first byte of imag
		temp2 = data;
		xil_printf("%c\n\r", temp2);
		data = XIOModule_DiscreteRead(&iomodule, 2); //read second byte of imag
		temp2 = data;
		xil_printf("%c\n\r", temp2);
		count++;
	}

	count = 0;
}

 cleanup_platform();
 return 0;
}

