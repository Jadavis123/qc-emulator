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

//Quantum Computer Finite State Machine

volatile char int_flag = 0;
void InterruptFlagSet(void* ref){
  int_flag = 1;
}

int main()
{
 init_platform();

 int count = 0;
 int numQ = 2;
 int numStates = (1 << numQ);
 int numInput = numStates * (numStates + 1);
 u32 data;
 XIOModule iomodule;
 u8 rx_buf[10];

 data = XIOModule_Initialize(&iomodule, XPAR_IOMODULE_0_DEVICE_ID);
 data = XIOModule_Start(&iomodule);

 microblaze_register_handler(XIOModule_DeviceInterruptHandler, XPAR_IOMODULE_0_DEVICE_ID);
 XIOModule_Connect(&iomodule, XIN_IOMODULE_GPI_2_INTERRUPT_INTR, InterruptFlagSet, NULL);
 XIOModule_Enable(&iomodule, XIN_IOMODULE_GPI_2_INTERRUPT_INTR);
 microblaze_enable_interrupts();

 print("Starting\n\r");
 while(count < numInput)
 {
	 while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0);
	 XIOModule_DiscreteWrite(&iomodule, 1, (u32) rx_buf[0]);
	 XIOModule_DiscreteWrite(&iomodule, 2, 1); //set the output flag high
	 while (XIOModule_Recv(&iomodule, rx_buf, 1) == 0);
	 XIOModule_DiscreteWrite(&iomodule, 1, (u32) rx_buf[0]);
	 XIOModule_DiscreteWrite(&iomodule, 2, 0); //set the output flag low
	 count++;
 }

 print("Receiving done\n\r");
 while(1)
 {
	while(int_flag == 0);
	while(count < numStates)
	{
		data = XIOModule_DiscreteRead(&iomodule, 1);
		xil_printf("%c\n\r", (u8) data);
		XIOModule_DiscreteWrite(&iomodule, 2, 1);
		data = XIOModule_DiscreteRead(&iomodule, 1);
		xil_printf("%c\n\r", (u8) data);
		XIOModule_DiscreteWrite(&iomodule, 2, 0);
		count++;
	}
 }

 cleanup_platform();
 return 0;
}

