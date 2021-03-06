# -*- coding: utf-8 -*-
"""
Created on Mon Jun  1 09:43:33 2020

@author: jacks
"""

import serial
import qutip as qt
from qutip.qip.operations import snot
from qutip.qip.operations import gate_expand_1toN
from numToByte import numToByte
from byteToNum import byteToNum
from measureTest import measure

ser = serial.Serial('COM4', 115200)
numQ = 2 #number of qubits
measureQ = 0 #index of qubit being measured
count = 0
outState = qt.basis(2**numQ) - qt.basis(2**numQ) #empty state of appropriate size
#-----------------------------------------------------------------------------
#State and gate to test
stateNotNorm = qt.basis(2**numQ, 0) + qt.basis(2**numQ, 2)
state = stateNotNorm.unit() #normalized input state
gate = gate_expand_1toN(snot(), numQ, 1) #testing gate
#gate = snot()
#-----------------------------------------------------------------------------
for i in range(2**numQ): #write each element of input state to serial as 8-bit fixed pt
    probAmp = state.__getitem__(i)[0][0]
    ser.write(numToByte(probAmp.real))
    ser.write(numToByte(probAmp.imag))
for j in range(2**numQ): #write each element of input gate to serial as 8-bit fixed pt
    rowArray = gate.__getitem__(j)
    row = rowArray[0]
    for num in row:
        ser.write(numToByte(num.real))
        ser.write(numToByte(num.imag))
print("Receiving")
while (count < 2**numQ): #read each element of output state and convert to float, then put into outState
    numRe = byteToNum(ser.readline().rstrip().lstrip()[0])
    numIm = byteToNum(ser.readline().rstrip().lstrip()[0])
    print(numRe, " + ", numIm, "j")
    outState += numRe*qt.basis(2**numQ, count) + numIm*1j*qt.basis(2**numQ, count)
    count+=1
outStateNorm = outState.unit()
print(outStateNorm)
print(measure(outStateNorm, measureQ, numQ)) #measure the chosen qubit and print the output

ser.close()