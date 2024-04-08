#!/usr/bin/python3

import re,os,sys

class CRC_32:
  def __init__(self):
    self.value = []
    self.crc32_block = []

  def openfile(self):
    count = 0
    k = 1
    romcode_file = open('img_hex.txt','r')
    for line in romcode_file:
      #if (count < 256*k):
        #       count = count + 1
      if (count == 256*k):
      #else:
        crc32 = self.compute()
        #count = 0
        print(crc32)
        self.crc32_block.append(crc32)
        k = k + 1
        self.value = []
        if (k>16):
          break
      count = count + 1
      #value= ["7d","00","00","00","00"]
      line = line.strip()
      value = [line[i:i+2] for i in range (len(line),-1,-2)]
      self.value += value[1:5]

    print ("Block CRC calculated")
    print (self.crc32_block)

  def compute(self):
    i = None
    j = None
    k = None
    bit = None
    datalen = None
    length = None
    actchar = None
    flag = None
    counter = None
    c = None
    crc = [0,0,0,0,0,0,0,0,0]
    mask = [0,0,0,0,0,0,0,0]
    hexnum = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
    data = []
    polynom = []
    init = [0,0,0,0,0,0,0,0]
    xor = [0,0,0,0,0,0,0,0]
    order= "32"
    #value= ["7d","00"]
    # convert crc polynom
    polynom = ["00","00","00","00","82","60","8e","db"]

    # generate bit mask
    counter = int(order)
    for i in range (7,-1,-1): #(i=7; i>=0; i--)
      if (counter>=8):
        mask[i] = 255
      else:
        mask[i]=(1<<counter)-1
      counter-=8
      if (counter<0):
        counter=0
    crc = init
    crc.append(0)

    for i in range (0, int(order)):
      bit = crc[7-((int(order)-1)>>3)] & (1<<((int(order)-1)&7))
      for k in range (0,8):
        crc[k] = ((crc [k] << 1) | (crc [k+1] >> 7)) & mask [k]
        if (bit):
          crc[k]= (crc[k] ^ int(polynom[k],16))
    data = self.value
    datalen = len(data)
    length=0                     # number of data bytes

    crc[8]=0

# main loop, algorithm is fast bit by bit type
    for i in range (0, datalen):
      #ch = int(data[i+1], 16)
      #i = i+1
      #c = int(data[i], 16)
      c = int(data[i],16)
# rotate one data byte including crcmask
      for j in range (0,8):
        bit=0
        if (crc[7-((int(order)-1)>>3)] & (1<<((int(order)-1)&7))):
          bit=1
        if (c&0x80):
          bit= (bit ^ 1)
        c<<=1
        for k in range (0,8):           ## rotate all (max.8) crc bytes
          crc[k] = ((crc [k] << 1) | (crc [k+1] >> 7)) & mask [k]
          if (bit):
            crc[k]= (crc[k] ^ int(polynom[k],16))
      length = length+1
      #print "%02x%02x%02x%02x" % (crc[4],crc[5],crc[6],crc[7])
## perform xor value
    for i in range (0, 8):
      crc [i] ^= xor [i]
    #print "Block is done"
## write result
    value_out = ""

    flag=0
    for i in range (0, 8):
      actchar = crc[i]>>4
      print("actchar is", actchar)
      if (flag or actchar):
        value_out+= hexnum[actchar]
        flag=1
      actchar = crc[i] & 15
      if (flag or actchar or i==7):
        value_out+= hexnum[actchar]
        flag=1
    print("value_out is",value_out)
    return value_out

  def get_crc(self):
    print ("self.crc32_block is", self.crc32_block)
    return self.crc32_block


