# -*- coding: utf-8 -*-
"""
Created on Tue May 19 12:29:58 2020

@author: jacks
"""

import serial

ser = serial.Serial('COM4', 9600)
ser.write(b'c')
print(ser.readline())
print(ser.readline())
ser.close()