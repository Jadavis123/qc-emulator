# -*- coding: utf-8 -*-
"""
Created on Fri May 29 13:06:13 2020

@author: jacks
"""

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