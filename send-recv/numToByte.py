# -*- coding: utf-8 -*-
"""
Created on Wed May 20 14:00:52 2020

@author: jacks
"""

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