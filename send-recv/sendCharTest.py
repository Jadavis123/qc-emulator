# -*- coding: utf-8 -*-
"""
Created on Tue May 19 12:29:58 2020

@author: jacks
"""

import serial
import time
from numToByte import numToByte

ser = serial.Serial('COM4', 9600)
num = 1
numByte = numToByte(num)
ser.write(numByte)
print(ser.readline().rstrip().lstrip())
print(ser.readline().rstrip().lstrip())
ser.write(numByte)
print(ser.readline().rstrip().lstrip())
print(ser.readline().rstrip().lstrip())
ser.close()