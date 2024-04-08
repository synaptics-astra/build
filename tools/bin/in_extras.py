#!/usr/bin/python3

import struct
import sys
import os
import textwrap
import subprocess
from crc_calc import CRC_32

def convert_to_hex_string():
    args = ['xxd', '-e', '-p', './tmp_img.bin', './tmp_img.txt']
    subprocess.call(args)

    file1 = open('tmp_img.txt', 'r')
    file2 = open('img_hex.txt', 'a')
    value = file1.read().replace("\n", "")
    file1.close()

    # Wrap this text.
    wrapper = textwrap.TextWrapper(width=8)
    word_list = wrapper.wrap(text=value)

    # Print each line.
    for line in word_list:
        line1 = line[6:8] + line[4:6] + line[2:4] + line[0:2]
        print(line1)
        file2.write(line1 + '\n')

    file2.write("        ")
    file2.close()

def x_convert1(infile, outfile, offset):
  crcList = []
  crcList_tmp = []
  img_data_len = 16*1024  #16k
  ibus_len = 64
  dbus_len = 64

  crcStartAddr = offset
 # TO DO
  ibusFilter = bytes(ibus_len)
  dbusFilter = bytes(dbus_len)

  with open(infile, 'rb') as f, open('tmp_img.bin', 'wb') as tf:
    strb = f.read(img_data_len)
    lenb = len(strb)
    print("img len:", lenb)

    #if image lenth is less than 16k, then pad 0 to 16k
    if lenb < img_data_len:
        strb = strb + bytes(img_data_len-lenb)
    tf.write(strb)

    #convert image data to hex type
    convert_to_hex_string()

    #calculate crc
    vpro = CRC_32()
    vpro.openfile()
    crcList_tmp = vpro.get_crc()

  for i in range(16):
    tst = int(crcList_tmp[i],16)
    crcList.append(tst)

  print ("crcList is", crcList)
  with open(outfile, 'wb') as of:
    a = struct.pack("<I", crcStartAddr)
    print (a)
    of.write(a)
    a = struct.pack("<16I", *crcList)
    of.write(a)
    of.write(ibusFilter)
    of.write(dbusFilter)
    os.system("rm ./tmp_img.bin")
    os.system("rm ./tmp_img.txt")
    os.system("rm ./img_hex.txt")
   # os.system("rm ./tmp.txt")

def x_convert2(outfile, *args):
  with open(outfile, 'wb') as of:
    for x_data in args:
      x_data1 = int(x_data,16)
      print("x_data is",hex(x_data1))
      a = struct.pack("<I", x_data1)
      of.write(a)

if __name__ == "__main__":
  len(sys.argv)
  img_type = sys.argv[1]

  print("image type is ", img_type)

  if img_type == 'EROM' or img_type == "BCM_KERNEL":
    infile = sys.argv[2]
    outfile = sys.argv[3]
    offset = int((sys.argv[4]),16)
    print("offset is",hex(offset))

    x_convert1(infile, outfile, offset)

  elif img_type == 'DIF'or img_type == 'BOOTMONITOR' or img_type == 'MINILOADER' or img_type == 'UBOOT' or img_type == 'BOOT_LOADER'or img_type == 'LINUX_KERNEL' or img_type == 'SCS_DATA_PARAM' or img_type == 'SYS_INIT' or img_type == 'SM_FW' or img_type == 'AVB_KEYS' or img_type == 'FASTBOOT' or img_type == 'FASTLOGO':
    outfile = sys.argv[2]
    x_convert2(outfile, sys.argv[3])

  elif img_type == 'TZ_KERNEL' or img_type == 'ATF' or img_type ==  'TZK_BOOT_PARAMETER' or img_type == 'TZK_OEM_SETTINGS':
    outfile = sys.argv[2]
    x_convert2(outfile, sys.argv[3], sys.argv[4])

  elif img_type == 'TZK_CONTAINER_HEADER':
    outfile = sys.argv[2]
    x_convert2(outfile, sys.argv[3], sys.argv[4], sys.argv[5])

  elif img_type == 'DSP_FW' or img_type == 'GPU_FW' or img_type == 'TSP_FW':
    outfile = sys.argv[2]
    x_convert2(outfile, sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
  else: #TO DO
    print("unkonw image type")
    sys.exit(1)

  sys.exit(0)

