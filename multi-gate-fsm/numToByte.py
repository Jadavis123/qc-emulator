# -*- coding: utf-8 -*-
"""
Created on Wed May 20 14:00:52 2020

@author: jacks
"""

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