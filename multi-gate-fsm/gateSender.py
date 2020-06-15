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
state = qt.basis(2**numQ, 1)
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#Gates (operate on state from highest to lowest)
gates = []
gates.append(gate_expand_1toN(snot(), numQ, 0))
gates.append(gate_expand_1toN(snot(), numQ, 1))
gates.append(qt.tensor(qt.qeye(2), qt.sigmax()))
gates.append(gate_expand_1toN(snot(), numQ, 0))
#-----------------------------------------------------------------------------

for i in range(2**numQ):
    probAmp = state.__getitem__(i)[0][0]
    re = numToByte(probAmp.real) #convert real float into 16-bit fixed point
    im = numToByte(probAmp.imag) #convert imag float into 16-bit fixed point
    ser.write(re[0]) #first 8 bits of real component
    ser.write(re[1]) #last 8 bits of real component
    ser.write(im[0]) #first 8 bits of imaginary component
    ser.write(im[1]) #last 8 bits of imaginary component

for gate in gates :
    #write byte that signifies whether current gate is the last one or not
    if (gateCount == len(gates)-1):    
        ser.write(LAST)
    else:
        ser.write(NOT_LAST)
    #write each value in gate to serial
    for j in range(2**numQ):
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
#normalize output state, unless it is empty - real states cannot be all 0 because
#that is not normalizable, but this avoids a crash if there is a logic error
if (outState != qt.basis(2**numQ, 0) - qt.basis(2**numQ, 0)) :
    outState = outState.unit()
print(outState)
print(measure(outState, measureQ, numQ)) #measure the chosen qubit and print the output

ser.close()