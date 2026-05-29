# Bash script: boot_type: NAND

#############
# Functions #
#############

set -o errtrace
trap 'echo Fatal error: script $0 aborting at ${BASH_SOURCE}:$LINENO, command \"$BASH_COMMAND\" returned $? 1>&2; exit 1' ERR

xspi_release_subimg() {
  local subimg_file
  local subimg_name

  subimg_file=$1; shift
  subimg_name=$1; shift

  [ -f ${outdir_subimg_intermediate}/${subimg_file}.subimg ]

  # Copy subimg file to release directory
  cat ${outdir_subimg_intermediate}/${subimg_file}.subimg > ${outdir_product_release_xspi}/${subimg_name}.subimg
}

xspi_release_subimg_imagelist() {
  local subimg_file
  local name_list

  subimg_file=$1; shift
  name_list=$1; shift

  for n in ${name_list}; do
    eval name=\$$n

    if [ "${name}" == "${subimg_file}" ]; then
      xspi_release_subimg $subimg_file $n
    fi
  done
}

spi_suboot_combo() {
  # Parse arguments
  local f_bootinfo
  local f_preboot
  local f_sysmgr
  local f_tzk
  local f_bl
  local f_spi_combo

  f_bootinfo=$1; shift
  f_preboot=$1; shift
  f_sysmgr=$1; shift
  f_tzk=$1; shift
  f_bl=$1; shift
  f_spi_combo=$1; shift

  local spi_vt_file="${outdir_subimg_intermediate}/version_table"
  local spi_vt_size=2048

  # Append bootinfo
  cat $f_bootinfo > $f_spi_combo
  f_bootinfo_size=`stat -c %s ${f_spi_combo}`
  if [ $f_bootinfo_size -gt $xspi_bootinfo_part_size ]; then echo "Error: bootinfo too large"; exit 1; fi
  padding_size=$[$xspi_bootinfo_part_size - $f_bootinfo_size]
  if [ $padding_size -gt 0 ]; then
    dd if=/dev/zero bs=$padding_size count=1 >> $f_spi_combo 2>/dev/null
  fi

  # Append preboot and version table
  f_preboot_size=`stat -c %s ${f_preboot}`
  if [ $f_preboot_size -gt $xspi_preboot_part_size ]; then echo "Error: preboot too large"; exit 1; fi

  [ ! $(( $f_preboot_size + $spi_vt_size )) -gt ${xspi_preboot_part_size} ]
  fill_length=$(( ${xspi_preboot_part_size} - ${spi_vt_size} - ${f_preboot_size} ))

  if [ $fill_length -gt 0 ]; then
    dd if=/dev/zero bs=$fill_length count=1 >> ${f_preboot} 2>/dev/null
  fi

  cat ${spi_vt_file} >> ${f_preboot}
  f_preboot_size=`stat -c %s ${f_preboot}`
  [ ! $f_preboot_size -gt ${xspi_preboot_part_size} ]

  fill_length=$(( ${xspi_preboot_part_size} - ${f_preboot_size} ))
  if [ $fill_length -gt 0 ]; then
    dd if=/dev/zero bs=$fill_length count=1 >> ${f_preboot} 2>/dev/null
  fi
  cat $f_preboot >> $f_spi_combo

  # Append sysmgr
  cat $f_sysmgr >> $f_spi_combo
  f_sysmgr_size=`stat -c %s ${f_sysmgr}`
  if [ $f_sysmgr_size -gt $xspi_sysmgr_part_size ]; then echo "Error: sysmgr too large"; exit 1; fi
  padding_size=$[$xspi_sysmgr_part_size - $f_sysmgr_size]
  if [ $padding_size -gt 0 ]; then
    dd if=/dev/zero bs=$padding_size count=1 >> $f_spi_combo 2>/dev/null
  fi

  # Append TZK
  cat $f_tzk >> $f_spi_combo
  f_tzk_size=`stat -c %s ${f_tzk}`
  if [ $f_tzk_size -gt $xspi_tzk_part_size ]; then echo "Error: TZK too large"; exit 1; fi
  padding_size=$[$xspi_tzk_part_size - $f_tzk_size]
  if [ $padding_size -gt 0 ]; then
    dd if=/dev/zero bs=$padding_size count=1 >> $f_spi_combo 2>/dev/null
  fi

  # Append BL
  cat $f_bl >> $f_spi_combo
  f_bl_size=`stat -c %s ${f_bl}`
  if [ $f_bl_size -gt $xspi_bl_part_size ]; then echo "Error: BL too large"; exit 1; fi
  padding_size=$[$xspi_bl_part_size - $f_bl_size]
  if [ $padding_size -gt 0 ]; then
    dd if=/dev/zero bs=$padding_size count=1 >> $f_spi_combo 2>/dev/null
  fi
}

########
# Main #
########

#
# Preparation
#
basedir_tools=${CONFIG_SYNA_SDK_PATH}/${CONFIG_TOOLS_BIN_PATH}
outdir_subimg_intermediate=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/obj/PACKAGING/subimg_intermediate
workdir_product_config=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
mkdir -p ${outdir_subimg_intermediate}

#
# Generate single subimage (for eng only)
#
if [ $# -eq 2 ]; then
  flag=${1}
  singleimage=${2}
  if [ "is${flag}" = "issingle" ]; then
    if [ "is${singleimage}" != "is" ]; then
      echo "pack ${singleimage} start"
      source ${basedir_script_subimg}/${singleimage}/common.bashrc
      source ${basedir_script_subimg}/${singleimage}/xspi.bashrc
      echo "pack ${singleimage} done"
      exit 0
    fi
  fi
fi

### EMMC Flash Type ###
source ${script_dir}/xspi_flash_type.bashrc

### Handle version table ###
source ${script_dir}/xspi_version_table.bashrc

# install the mapping
source ${script_dir}/image_mapping.bashrc

mv ${outdir_subimg_intermediate}/xspi_image_list ${outdir_subimg_intermediate}/xspi_image_list.old
cat ${outdir_subimg_intermediate}/xspi_image_list.old \
   | sed 's/_a.subimg/.subimg/g;s/_b.subimg/.subimg/g' \
   > ${outdir_subimg_intermediate}/xspi_image_list

# obtain the subimage list
subimg_list=`cat ${outdir_subimg_intermediate}/xspi_image_list | grep 'subimg' | cut -d . -f1`

#
# Generate subimages
#

### Bootinfo ###
source ${basedir_script_subimg}/bootinfo/common.bashrc
source ${basedir_script_subimg}/bootinfo/xspi.bashrc

### Preboot ###
source ${basedir_script_subimg}/preboot/common.bashrc
source ${basedir_script_subimg}/preboot/xspi.bashrc

### TEE ###
source ${basedir_script_subimg}/tee/common.bashrc
source ${basedir_script_subimg}/tee/xspi.bashrc

if [ "is${CONFIG_UBOOT_SPIUBOOT}" = "isy" ]; then
  echo "SPI_Uboot Image Generation"
  cat ${outdir_subimg_intermediate}/bootinfo.subimg \
      ${outdir_subimg_intermediate}/preboot.subimg \
      ${outdir_subimg_intermediate}/sysmgr.subimg \
      ${outdir_subimg_intermediate}/tee.subimg \
      ${outdir_subimg_intermediate}/uboot.subimg \
      > ${outdir_subimg_intermediate}/spi_uboot_en.bin
  echo "SPI U-boot combo: ${outdir_subimg_intermediate}/spi_uboot_en.bin"
  exit 0
fi

### Bootloader ###
source ${basedir_script_subimg}/bootloader/common.bashrc
source ${basedir_script_subimg}/bootloader/xspi.bashrc

### Firmware_SM ###
if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  source ${basedir_script_subimg}/firmware/common.bashrc
  source ${basedir_script_subimg}/firmware/xspi.bashrc
fi

### Preload TA ###
if [ "is${CONFIG_BL_PRELOAD_TA}" = "isy" ]; then
  source ${basedir_script_subimg}/preload_ta/common.bashrc
  source ${basedir_script_subimg}/preload_ta/xspi.bashrc
fi

### Fastlogo  ###
if [ "is${CONFIG_BL_FASTLOGO}" = "isy" ]; then
    source ${basedir_script_subimg}/fastlogo/common.bashrc
    source ${basedir_script_subimg}/fastlogo/xspi.bashrc
fi
#
# Notice: Key has denpendency on Preboot task !
#
### Key ###
source ${basedir_script_subimg}/key/common.bashrc
source ${basedir_script_subimg}/key/xspi.bashrc

#
# Notice: Fastboot has denpendency on Preboot and Key tasks !
#
### Fastboot ###
if [ "is${CONFIG_UBOOT_FASTBOOT}" == "isy" ]; then
  [ "is${CONFIG_PREBOOT_BOOTFLOW_SPIUBOOT}" != "isy" ]
  source ${basedir_script_subimg}/uboot/common.bashrc
  source ${basedir_script_subimg}/uboot/xspi.bashrc
fi

### Kernel/RAMDISK ###
source ${basedir_script_subimg}/linux_bootimgs/common.bashrc
source ${basedir_script_subimg}/linux_bootimgs/xspi.bashrc

### Filesystems ###
if [ "has${CONFIG_RUNTIME_FILESYSTEMS}" != "has" ]; then
  source ${basedir_script_subimg}/fsimgs/common.bashrc

  system_partition_name="system"
  for item in ${subimg_list}; do
    eval item_name=\$$item
    if [ "${item_name}" == "system" ]; then
      system_partition_name="${item}"
      break;
    fi
  done
  source ${basedir_script_subimg}/fsimgs/xspi.bashrc
fi

#
# Generate spi combo images
#
outdir_product_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/release
outdir_product_release_spi=${outdir_product_release}/spi
mkdir -p ${outdir_product_release_spi}

spi_suboot_combo \
  ${outdir_subimg_intermediate}/bootinfo.subimg \
  ${outdir_subimg_intermediate}/preboot.subimg \
  ${outdir_subimg_intermediate}/sysmgr.subimg \
  ${outdir_subimg_intermediate}/tee.subimg \
  ${outdir_subimg_intermediate}/bootloader.subimg \
  ${outdir_product_release_spi}/spi_suboot.bin

  cp ${outdir_subimg_intermediate}/linux_bootimgs.subimg ${outdir_product_release_spi}/boot.subimg

#
# Generate EMMC images
#
product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
outdir_product_release_xspi=${outdir_product_release}/xSPIimg
mkdir -p ${outdir_product_release_xspi}

#cat ${outdir_subimg_intermediate}/xspi_image_list \
#  | sed -e 's/\(\.subimg\),/\1.gz,/' \
#  > ${outdir_product_release_xspi}/xspi_image_list
cat ${outdir_subimg_intermediate}/xspi_image_list > ${outdir_product_release_xspi}/xspi_image_list
cp -ad ${outdir_subimg_intermediate}/xspi_part_list ${outdir_product_release_xspi}/.

# Prepare subimg info
xspi_release_subimg_imagelist "bootinfo" "${subimg_list}"
xspi_release_subimg_imagelist "preboot" "${subimg_list}"
xspi_release_subimg_imagelist "tee" "${subimg_list}"
xspi_release_subimg_imagelist "tee_recovery" "${subimg_list}"

if [ "is${CONFIG_GENX_MCU}" = "isy" ]; then
  xspi_release_subimg_imagelist "sysmgr" "${subimg_list}"
fi

if [ "is${CONFIG_ANDROID_OS}" == "isy" ]; then
  xspi_release_subimg_imagelist "fastboot" "${subimg_list}"
fi

xspi_release_subimg_imagelist "bootloader" "${subimg_list}"

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  xspi_release_subimg_imagelist "firmware" "${subimg_list}"
fi

xspi_release_subimg_imagelist "key" "${subimg_list}"

xspi_release_subimg_imagelist "linux_bootimgs" "${subimg_list}"

if [ "has${CONFIG_RUNTIME_FILESYSTEMS}" != "has" ]; then
  xspi_release_subimg_imagelist "system" "${subimg_list}"
fi

if [ "is${CONFIG_UBOOT_FASTBOOT}" == "isy" ]; then
  [ "is${CONFIG_PREBOOT_BOOTFLOW_SPIUBOOT}" != "isy" ]
  xspi_release_subimg_imagelist "fastboot" "${subimg_list}"
fi

if [ "is${CONFIG_BL_FASTLOGO}" == "isy" ]; then
  xspi_release_subimg_imagelist "fastlogo" "${subimg_list}"
fi

if [ "is${CONFIG_EXT_PREBOOT_BOOTFLOW_AB}" = "isy" ];then
    if [ -f ${product_dir}/misc.subimg.gz ]; then
        cp ${product_dir}/misc.subimg.gz ${outdir_product_release_xspi}
    fi
fi
