# -*- coding: utf-8 -*-
"""
Created on Thu May 21 10:04:23 2020

@author: jacks
"""

from qutip.qip.operations import snot
from qutip.qip.operations import gate_expand_1toN

import serial
from struct import unpack

def numToByte(num) :
    out = bytearray()
    tot = 0
    if (num < 0) :
        tot+=128
        num = num*-1
    if (num == 1) :
        tot+=64
        num -=1
    if (num >= 0.5) :
        tot+=32
        num-=0.5
    if (num >= 0.25) :
        tot+=16
        num-=0.25
    if (num >= 0.125) :
        tot+=8
        num-=0.125
    if (num >= 0.0625) :
        tot+=4
        num-=0.0625
    if (num >= 0.03125) :
        tot+=2
        num-=0.03125
    if (num >= 0.015625) :
        tot+=1
        num-=0.015625
    out.append(tot)
    return out

def byteToNum(num):
    tot = 0.0
    negative = False
    if (num >= 128):
        negative = True
        num = num - 128
    if (num >= 64):
        tot+=1.0
        num = num - 64
    if (num >= 32):
        tot+=0.5
        num = num - 32
    if (num >= 16):
        tot+=0.25
        num = num - 16
    if (num >= 8):
        tot+=0.125
        num = num - 8
    if (num >= 4):
        tot+=0.0625
        num = num - 4
    if (num >= 2):
        tot+=0.03125
        num = num - 2
    if (num >= 1):
        tot+=0.015625
        num = num - 1
    if (negative):
        tot = -tot
    return tot

ser = serial.Serial('COM4', 9600)
j = 1
numQ = 2
nums = []
gate = gate_expand_1toN(snot(), numQ, 1)
for i in range(2**numQ):
     rowArray = gate.__getitem__(i)
     row = rowArray[0]
     for num in row:
         nums.append(numToByte(num.real))
         nums.append(numToByte(num.imag))
for num in nums:
    ser.write(num)
    print(j, ": ", byteToNum(ser.readline().rstrip().lstrip()[0]))
    j+=1
ser.close()