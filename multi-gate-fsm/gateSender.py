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
import random
import time
    
#Constant bytearrays for signifying if each gate is the last in the sequence or not
NOT_LAST = bytearray()
NOT_LAST.append(1)
LAST = bytearray()
LAST.append(0)

numQ = 2 #number of qubits   
measureQ = 0 #index of qubit being measured 

#-----------------------------------------------------------------------------
#Initial state
state = qt.basis(2**numQ, 1)
#-----------------------------------------------------------------------------
   
#-----------------------------------------------------------------------------
#Gates (operate on state from highest to lowest)
gates = []
gates.append(gate_expand_1toN(snot(), numQ, 1))
gates.append(gate_expand_1toN(snot(), numQ, 1))
gates.append(qt.tensor(qt.qeye(2), qt.sigmax()))
gates.append(gate_expand_1toN(snot(), numQ, 0))
#-----------------------------------------------------------------------------

def emulate():
    ser = serial.Serial('COM4', 115200)  #open COM4 port at 115200 baud
    count = 0
    gateCount = 0
    outState = qt.basis(2**numQ) - qt.basis(2**numQ) #empty state of appropriate size
    startTime = time.time() #start the timer here, since gate creation runtime is inconsistent
    #Loop through each element in state and send it to MicroBlaze
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
    endTime = time.time()
    print("Runtime: ", endTime-startTime, " s")


#Converts a floating point number to a 16-bit fixed point number, where the first
#bit is the sign (0=positive, 1=negative), the second bit is the integer portion
#(0 or 1), and the following 14 bits are 1/2, 1/4, 1/8, etc.
#e.g. 1111 0000 0000 0000 = -1.75
#The method stores the 'total' as an int, because appending the int to a bytearray()
#interprets it as an 8-bit int
#Because the MicroBlaze can only receive 1 byte at a time, we have to use 2 separate
#bytearrays for each number 

def numToByte(num) :
    out1 = bytearray()
    out2 = bytearray()
    tot1 = 0
    tot2 = 0
    if (num < 0) :
        tot1+=128
        num = num*-1
    for i in range(7) :
        if (num >= 2**(-i)):
            tot1+=2**(6-i)
            num-=2**(-i)
    out1.append(tot1)
    for i in range(8) :
        if (num >= 2**(-7-i)):
            tot2+=2**(7-i)
            num-=2**(-7-i)
    out2.append(tot2)
    return [out1, out2]

#Performs the reverse of the process described in numToByte.py to convert 2 bytes
#to a 16-bit fixed point number

def byteToNum(num1, num2):
    tot = 0.0
    negative = False
    if (num1 >= 128):
        negative = True
        num1 = num1 - 128
    for i in range(7):
        if (num1 >= 2**(6-i)):
            tot+=2**(-i)
            num1-=2**(6-i)
    for i in range(8):
        if (num2 >= 2**(7-i)):
            tot+=2**(-7-i)
            num2-=2**(7-i)
    if (negative):
        tot = -tot
    return tot

#for a given index and number of qubits, finds binary representation of index 
#representing state of qubits, e.g. index 2 in a state of 2 qubits corresponds to |10>
def indexToBits(i, N) :
    bits = []
    for j in range(1, N+1) :
        num = 2**(N-j)
        if (i >= num):
            bits.append(1)
            i = i - num
        else:
            bits.append(0)
    return bits

def measure(state, i, N):
    outState = qt.basis(2**N, 0) - qt.basis(2**N, 0)
    num = random.random()
    total = 0
    #calculate total probability of measuring given qubit to be 0
    for j in range(2**N):
        probAmp = state.__getitem__(j)[0][0]
        bitState = indexToBits(j, N)
        #add probability to total if prob amp corresponds to measuring qubit to be 0
        if (bitState[i] == 0):
            total += probAmp.real**2 + probAmp.imag**2
    #compares random number to probability of measuring 0 - if random number is 
    #greater, we have measured qubit to be 1 so we erase all amplitudes where it is 0
    if (num >= total):
        for j in range(2**N):
            probAmp = state.__getitem__(j)[0][0]
            bitState = indexToBits(j, N)
            if (bitState[i] == 1):
                outState = outState + probAmp*qt.basis(2**N, j)
    #if random number is smaller, we have measured qubit to be 0 so we erase all
    #amplitudes where it is 1
    else:
        for j in range(2**N):
            probAmp = state.__getitem__(j)[0][0]
            bitState = indexToBits(j, N)
            if (bitState[i] == 0):
                outState = outState + probAmp*qt.basis(2**N, j)
    #normalize state unless empty
    if (outState != qt.basis(2**N, 0) - qt.basis(2**N, 0)):
        outState = outState.unit()
    return outState