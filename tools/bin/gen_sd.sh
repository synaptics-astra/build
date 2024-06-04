#!/bin/bash

# This is the script to generate SD card image base on eMMCimg
# Relies on Linux tool "gzip", "gdisk" and "sgdisk"
# Follow the steps below
#   copy "gen_sd.sh" to eMMCimg
#   cd eMMCimg
#   ./gen_sd.sh
# You will find SD.img in eMMCimg folder
set -e

check_command() {
    local program_name="$1"

    if ! command -v "$program_name" &> /dev/null; then
        echo "Program '$program_name' is not installed. Exiting..."
        exit 1
    else
        echo "Program '$program_name' is installed."
    fi
}

check_command gzip
check_command gdisk
check_command sgdisk


SPARSE=0
BOOT_UUID="EF00"
MS_UUID="0700"

if ls *_s.subimg* 1> /dev/null 2>&1; then
    SPARSE=1
    mkdir -p tmp_subimg
    mv *_s.subimg* tmp_subimg/
fi

gzip -d *.gz -k

#
sd1=format
sd2=key.subimg
sd3=tzk.subimg
sd4=key.subimg
sd5=tzk.subimg
sd6=bl.subimg
sd7=bl.subimg
sd8=boot.subimg
sd9=boot.subimg
sd10=firmware.subimg
sd11=firmware.subimg
sd12=rootfs.subimg
sd13=rootfs.subimg
sd14=fastlogo.subimg
sd15=fastlogo.subimg
sd16=erase
sd17=erase
sd18=home.subimg
#

#
## img for SD
#
OUTPUT="SD.img"

dd if=/dev/zero of=$OUTPUT bs=1M count=7089

echo "Partitioning the SD image..."
gdisk ${OUTPUT} << EOF
o
Y
x
l
2
m

n
1
32768
+16M
0700
c
factory_setting

n
2

+1M
0700
c
2
key_a

n
3

+7M
0700
c
3
tzk_a

n
4

+1M
0700
c
4
key_b

n
5

+7M
0700
c
5
tzk_b

n
6

+16M
0700
c
6
bl_a

n
7

+16M
0700
c
7
bl_b

n
8

+32M
0700
c
8
boot_a

n
9

+32M
0700
c
9
boot_b

n
10

+32M
0700
c
10
firmware_a

n
11

+32M
0700
c
11
firmware_b

n
12

+1408M
0700
c
12
rootfs_a

n
13

+1408M
0700
c
13
rootfs_b

n
14

+16M
0700
c
14
fastlogo_a

n
15

+16M
0700
c
15
fastlogo_b

n
16

+2M
0700
c
16
devinfo

n
17

+2M
0700
c
17
misc

n
18

+4028M
0700
c
18
home

p
w
Y
EOF

SEEK=`sgdisk -i 1 $OUTPUT | grep "First sector" | awk '{print $3}'`

dd bs=512 if="$sd2" of=$OUTPUT seek=`sgdisk -i 2 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd3" of=$OUTPUT seek=`sgdisk -i 3 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd4" of=$OUTPUT seek=`sgdisk -i 4 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd5" of=$OUTPUT seek=`sgdisk -i 5 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd6" of=$OUTPUT seek=`sgdisk -i 6 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd7" of=$OUTPUT seek=`sgdisk -i 7 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd8" of=$OUTPUT seek=`sgdisk -i 8 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd9" of=$OUTPUT seek=`sgdisk -i 9 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd10" of=$OUTPUT seek=`sgdisk -i 10 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd11" of=$OUTPUT seek=`sgdisk -i 11 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd12" of=$OUTPUT seek=`sgdisk -i 12 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd13" of=$OUTPUT seek=`sgdisk -i 13 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd14" of=$OUTPUT seek=`sgdisk -i 14 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd15" of=$OUTPUT seek=`sgdisk -i 15 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc
dd bs=512 if="$sd18" of=$OUTPUT seek=`sgdisk -i 18 $OUTPUT | grep "First sector" | awk '{print $3}'` conv=notrunc

rm *.subimg

if [ "$SPARSE" -eq 1 ]; then
    mv tmp_subimg/* ./ -f
    rm tmp_subimg -rf
fi
