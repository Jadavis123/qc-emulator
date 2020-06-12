# -*- coding: utf-8 -*-
"""
Created on Mon Jun  1 09:43:33 2020

@author: jacks
"""

import serial
import qutip as qt
from qutip.qip.operations import snot
from qutip.qip.operations import gate_expand_1toN
from qutip.qip.operations import cnot
from numToByte import numToByte
from byteToNum import byteToNum
from measureTest import measure

ser = serial.Serial('COM4', 115200)
numQ = 2 #number of qubits
measureQ = 0 #index of qubit being measured
count = 0
gateCount = 0
outState = qt.basis(2**numQ) - qt.basis(2**numQ) #empty state of appropriate size

#Constant bytearrays for signifying if each gate is the last in the sequence or not
NOT_LAST = bytearray()
NOT_LAST.append(1)
LAST = bytearray()
LAST.append(0)

#-----------------------------------------------------------------------------
#Initial state
state = qt.basis(2**numQ, 0)
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#Gates (operate on state from highest to lowest)
gates = []
#gates.append(gate_expand_1toN(snot(), numQ, 0))
gates.append(cnot(numQ, 0, 1))
gates.append(cnot(numQ, 0, 1))
gates.append(cnot(numQ, 0, 1))
#-----------------------------------------------------------------------------

for i in range(2**numQ): #write each element of input state to serial as 8-bit fixed pt
    probAmp = state.__getitem__(i)[0][0]
    re = numToByte(probAmp.real)
    im = numToByte(probAmp.imag)
    ser.write(re[0])
    ser.write(re[1])
    ser.write(im[0])
    ser.write(im[1])

for gate in gates :
    print(gateCount)
    if (gateCount == len(gates)-1):    
        ser.write(LAST)
        print("last")
    else:
        ser.write(NOT_LAST)
    for j in range(2**numQ): #write each element of input gates to serial as 8-bit fixed pt
        rowArray = gate.__getitem__(j)
        row = rowArray[0]
        for num in row:
            re = numToByte(num.real)
            im = numToByte(num.imag)
            ser.write(re[0])
            ser.write(re[1])
            ser.write(im[0])
            ser.write(im[1])
    gateCount+=1

#Receive output
while (count < 2**numQ): #read each element of output state and convert to float, then put into outState
    num1 = ser.readline().rstrip().lstrip()[0]
    num2 = ser.readline().rstrip().lstrip()[0]
    numRe = byteToNum(num1, num2)
    num1 = ser.readline().rstrip().lstrip()[0]
    num2 = ser.readline().rstrip().lstrip()[0]
    numIm = byteToNum(num1, num2)
    print(numRe, " + ", numIm, "j")
    outState += numRe*qt.basis(2**numQ, count) + numIm*1j*qt.basis(2**numQ, count)
    count+=1
if (outState != qt.basis(2**numQ, 0) - qt.basis(2**numQ, 0)) :
    outState = outState.unit()
print(outState)
print(measure(outState, measureQ, numQ)) #measure the chosen qubit and print the output

ser.close()