# -*- coding: utf-8 -*-
"""
Created on Wed May 27 14:23:33 2020

@author: jacks
"""

import qutip as qt
import time
import matplotlib.pyplot as plt

times = []
startN = 1
endN = 29
stepN = 1
for N in range(startN, endN+1, stepN) :
    state = qt.basis(2**N, 0) + qt.basis(2**N, 1)
    start = time.time()
    norm = state.unit()
    end = time.time()
    times.append(end-start)
plt.plot(times)
plt.xlabel("Number of qubits")
plt.ylabel("Running time (s)")
