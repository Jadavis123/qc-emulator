# -*- coding: utf-8 -*-
"""
Created on Fri May 29 13:06:13 2020

@author: jacks
"""

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