# -*- coding: utf-8 -*-
"""
Created on Thu May 28 09:43:02 2020

@author: jacks
"""

import qutip as qt
import random
import time
import matplotlib.pyplot as plt

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
    for j in range(2**N):
        probAmp = state.__getitem__(j)[0][0]
        bitState = indexToBits(j, N)
        if (bitState[i] == 0):
            total += probAmp.real**2 + probAmp.imag**2
    if (num >= total):
        for j in range(2**N):
            probAmp = state.__getitem__(j)[0][0]
            bitState = indexToBits(j, N)
            if (bitState[i] == 1):
                outState = outState + probAmp*qt.basis(2**N, j)
    else:
        for j in range(2**N):
            probAmp = state.__getitem__(j)[0][0]
            bitState = indexToBits(j, N)
            if (bitState[i] == 0):
                outState = outState + probAmp*qt.basis(2**N, j)
    return outState.unit()

#state = qt.basis(8, 0) + qt.basis(8, 1)
#normState = state.unit()
#print(measure(normState, 2, 3).unit())

minN = 1
maxN = 20
stepN = 1
times = []
for N in range(minN, maxN, stepN):
    state = qt.basis(2**N)
    startTime = time.time()
    measure(state, 0, N)
    endTime = time.time()
    times.append(endTime-startTime)
plt.plot(times)
plt.xlabel("Number of qubits")
plt.ylabel("Running time (s)")