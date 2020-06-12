# -*- coding: utf-8 -*-
"""
Created on Wed May 20 14:00:52 2020

@author: jacks
"""

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