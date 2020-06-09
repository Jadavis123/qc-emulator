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
outState = qt.basis(2**numQ) - qt.basis(2**numQ) #empty state of appropriate size

#Constant bytearrays for signifying if each gate is the last in the sequence or not
NOT_LAST = bytearray()
NOT_LAST.append(1)
LAST = bytearray()
LAST.append(0)

#-----------------------------------------------------------------------------
#Initial state
state = qt.basis(2**numQ, 2)
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#Gates (operate on state from highest to lowest)
gates = []
gates.append(gate_expand_1toN(snot(), numQ, 0))
gates.append(cnot(numQ, 0, 1))
#-----------------------------------------------------------------------------

for i in range(2**numQ): #write each element of input state to serial as 8-bit fixed pt
    probAmp = state.__getitem__(i)[0][0]
    ser.write(numToByte(probAmp.real))
    ser.write(numToByte(probAmp.imag))

for gate in gates :
    if (gate == gates[-1]):    
        ser.write(LAST)
    else:
        ser.write(NOT_LAST)
    for j in range(2**numQ): #write each element of input gates to serial as 8-bit fixed pt
        rowArray = gate.__getitem__(j)
        row = rowArray[0]
        for num in row:
            ser.write(numToByte(num.real))
            ser.write(numToByte(num.imag))

#Receive output
while (count < 2**numQ): #read each element of output state and convert to float, then put into outState
    numRe = byteToNum(ser.readline().rstrip().lstrip()[0])
    numIm = byteToNum(ser.readline().rstrip().lstrip()[0])
    print(numRe, " + ", numIm, "j")
    outState += numRe*qt.basis(2**numQ, count) + numIm*1j*qt.basis(2**numQ, count)
    count+=1
if (outState != qt.basis(2**numQ, 0) - qt.basis(2**numQ, 0)) :
    outState = outState.unit()
print(outState)
print(measure(outState, measureQ, numQ)) #measure the chosen qubit and print the output

ser.close()