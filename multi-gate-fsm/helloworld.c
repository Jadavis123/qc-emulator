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

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiomodule.h"
#include <stdbool.h>

//Quantum Computer Finite State Machine - MicroBlaze code

int main()
{
init_platform();
int count = 0;
int gateCount = 0;
int numQ = 2; //number of qubits
int numState = (1 << numQ); //1<<numQ is equivalent to 2^numQ, but simpler
int numGate = numState * numState;
u32 data;
XIOModule iomodule;
u8 rx_buf[10];
u8 next_flag[10];
u32 temp, temp3;
u8 temp2;
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

