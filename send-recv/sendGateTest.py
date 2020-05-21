# -*- coding: utf-8 -*-
"""
Created on Thu May 21 10:04:23 2020

@author: jacks
"""

import qutip as qt
import serial
from numToByte import numToByte

ser = serial.Serial('COM4', 9600)
numQ = 2
nums = []
gate = qt.gate_expand_1toN(qt.snot(), numQ, 1)
for i in range(2**numQ):
     rowArray = gate.__getitem__(i)
     row = rowArray[0]
     for num in row:
         nums.append(numToByte(num.real))
         nums.append(numToByte(num.imag))
for num in nums:
    ser.write(num)
    print(ser.readline().rstrip().lstrip())
    print(ser.readline().rstrip().lstrip())
ser.close()