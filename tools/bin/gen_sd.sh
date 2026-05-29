#!/bin/bash

# This is the script to generate SD card image base on eMMCimg
# Relies on Linux tool "mkfs.ext4", "gzip", "sgdisk", "e2fsck" and "resize2fs"
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

check_command mkfs.ext4
check_command gzip
check_command sgdisk
check_command e2fsck
check_command resize2fs

SPARSE=0
SD_SIZE=11089
BOOT_UUID="EF00"
MS_UUID="0700"

if ls *_s.subimg* 1> /dev/null 2>&1; then
    SPARSE=1
    mkdir -p tmp_subimg
    mv *_s.subimg* tmp_subimg/
fi

echo "Preparing sub images..."
gzip -d *.gz -k

PARTITIONS_SL16X0=(
"1 32768 +16M 0700 factory_setting format"
"2 '' +1M 0700 key_a key.subimg"
"3 '' +7M 0700 tzk_a tzk.subimg"
"4 '' +1M 0700 key_b key.subimg"
"5 '' +7M 0700 tzk_b tzk.subimg"
"6 '' +16M 0700 bl_a bl.subimg"
"7 '' +16M 0700 bl_b bl.subimg"
"8 '' +32M 0700 boot_a boot.subimg"
"9 '' +32M 0700 boot_b boot.subimg"
"10 '' +5200M 0700 rootfs_a rootfs.subimg"
"11 '' +5200M 0700 rootfs_b rootfs.subimg"
"12 '' +16M 0700 fastlogo_a fastlogo.subimg"
"13 '' +16M 0700 fastlogo_b fastlogo.subimg"
"14 '' +2M 0700 devinfo erase"
"15 '' +2M 0700 misc erase"
"16 '' +444M 0700 home home.subimg"
)

PARTITIONS_SL261X=(
"1 32768 +16M 0700 factory_setting format"
"2 '' +1M 0700 key_a key.subimg"
"3 '' +7M 0700 tzk_a tzk.subimg"
"4 '' +1M 0700 key_b key.subimg"
"5 '' +7M 0700 tzk_b tzk.subimg"
"6 '' +2M 0700 sysmgr_a sysmgr.subimg"
"7 '' +14M 0700 bl_a bl.subimg"
"8 '' +2M 0700 sysmgr_b sysmgr.subimg"
"9 '' +14M 0700 bl_b bl.subimg"
"10 '' +32M 0700 boot_a boot.subimg"
"11 '' +32M 0700 boot_b boot.subimg"
"12 '' +2560M 0700 rootfs_a rootfs.subimg"
"13 '' +2560M 0700 rootfs_b rootfs.subimg"
"14 '' +2M 0700 devinfo erase"
"15 '' +2M 0700 misc erase"
"16 '' +444M 0700 home home.subimg"
)

if [ -f "sysmgr.subimg" ]; then
    PARTITIONS=("${PARTITIONS_SL261X[@]}")
else
    PARTITIONS=("${PARTITIONS_SL16X0[@]}")
fi

#
## img for SD
#
OUTPUT="SD.img"

dd if=/dev/zero of=$OUTPUT bs=1M count=$SD_SIZE

echo "Partitioning the SD image..."

#
# create partitions
#
sgdisk -o ${OUTPUT}

for entry in "${PARTITIONS[@]}"; do
    set -- $entry
    num=$1
    start=$2
    size=$3
    type=$4
    name=$5

    if [ "$start" = "''" ]; then
        start=""
    fi

    sgdisk -n ${num}:${start}:${size} \
           -t ${num}:${type} \
           -c ${num}:"${name}" \
           ${OUTPUT}
done

#
# write data to partition
#
for entry in "${PARTITIONS[@]}"; do
    set -- $entry
    num=$1
    size=$3
    name=$5
    image=$6

    if [ "$image" = "format" ]; then
        COUNT=$(echo $size | tr -cd '0-9')
        dd if=/dev/zero of=sd${num}.subimg bs=1M count=$COUNT
        mkfs.ext4 sd${num}.subimg
        dd bs=512 if=sd${num}.subimg of=$OUTPUT \
            seek=$(sgdisk -i $num $OUTPUT | grep "First sector" | awk '{print $3}') \
            conv=notrunc
        rm sd${num}.subimg

    elif [ "$image" = "erase" ]; then
        continue

    else
        if [ "$name" == "home" ]; then
            if [ ! -f "$image" ]; then
                COUNT=$(echo $size | tr -cd '0-9')
                dd if=/dev/zero of="$image" bs=1M count=$COUNT
                mkfs.ext4 "$image"
            fi
            e2fsck -f -y "$image" || true
            resize2fs "$image" "${size//+/}"
        fi
        dd bs=512 if="$image" of=$OUTPUT \
            seek=$(sgdisk -i $num $OUTPUT | grep "First sector" | awk '{print $3}') \
            conv=notrunc
    fi
done

rm *.subimg

if [ "$SPARSE" -eq 1 ]; then
    mv tmp_subimg/* ./ -f
    rm tmp_subimg -rf
fi
