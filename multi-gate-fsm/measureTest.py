# -*- coding: utf-8 -*-
"""
Created on Thu May 28 09:43:02 2020

@author: jacks
"""

import qutip as qt
import random
#import time
#import matplotlib.pyplot as plt

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

#state = qt.basis(8, 0) + qt.basis(8, 1)
#normState = state.unit()
#print(measure(normState, 2, 3).unit())

#minN = 1
#maxN = 10
#stepN = 1
#times = []
#for N in range(minN, maxN, stepN):
#    state = qt.basis(2**N)
#    startTime = time.time()
#    measure(state, 0, N)
#    endTime = time.time()
#    times.append(endTime-startTime)
#plt.plot(times)
#plt.xlabel("Number of qubits")
#plt.ylabel("Running time (s)")