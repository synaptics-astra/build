# Bash script: boot_type: NAND

#############
# Functions #
#############

emmc_release_subimg() {
  local subimg_file
  local subimg_name

  subimg_file=$1; shift
  subimg_name=$1; shift

  [ -f ${outdir_subimg_intermediate}/${subimg_file}.subimg ]

  # Copy subimg file to release directory
  cat ${outdir_subimg_intermediate}/${subimg_file}.subimg | gzip -1 > ${outdir_product_release_emmc}/${subimg_name}.subimg.gz
}

emmc_release_subimg_imagelist() {
  local subimg_file
  local name_list

  subimg_file=$1; shift
  name_list=$1; shift

  for n in ${name_list}; do
    eval name=\$$n

    if [ "${name}" == "${subimg_file}" ]; then
      emmc_release_subimg $subimg_file $n
    fi
  done
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
      source ${basedir_script_subimg}/${singleimage}/emmc.bashrc
      echo "pack ${singleimage} done"
      exit 0
    fi
  fi
fi

### EMMC Flash Type ###
source ${script_dir}/emmc_flash_type.bashrc

### Handle version table ###
source ${script_dir}/emmc_version_table.bashrc

# install the mapping
source ${script_dir}/image_mapping.bashrc

mv ${outdir_subimg_intermediate}/emmc_image_list ${outdir_subimg_intermediate}/emmc_image_list.old
cat ${outdir_subimg_intermediate}/emmc_image_list.old \
   | sed 's/_a.subimg/.subimg/g;s/_b.subimg/.subimg/g' \
   > ${outdir_subimg_intermediate}/emmc_image_list

# obtain the subimage list
subimg_list=`cat ${outdir_subimg_intermediate}/emmc_image_list | grep 'subimg' | cut -d . -f1`

#
# Generate subimages
#

### Preboot ###
source ${basedir_script_subimg}/preboot/common.bashrc
source ${basedir_script_subimg}/preboot/emmc.bashrc

### TEE ###
source ${basedir_script_subimg}/tee/common.bashrc
source ${basedir_script_subimg}/tee/emmc.bashrc

### Bootloader ###
source ${basedir_script_subimg}/bootloader/common.bashrc
source ${basedir_script_subimg}/bootloader/emmc.bashrc

### Firmware_SM ###
if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  source ${basedir_script_subimg}/firmware/common.bashrc
  source ${basedir_script_subimg}/firmware/emmc.bashrc
fi

### Preload TA ###
if [ "is${CONFIG_BL_PRELOAD_TA}" = "isy" ]; then
  source ${basedir_script_subimg}/preload_ta/common.bashrc
  source ${basedir_script_subimg}/preload_ta/emmc.bashrc
fi

### Fastlogo  ###
if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    source ${basedir_script_subimg}/fastlogo/common.bashrc
    source ${basedir_script_subimg}/fastlogo/emmc.bashrc
fi
#
# Notice: Key has denpendency on Preboot task !
#
### Key ###
source ${basedir_script_subimg}/key/common.bashrc
source ${basedir_script_subimg}/key/emmc.bashrc

#
# Notice: Fastboot has denpendency on Preboot and Key tasks !
#
### Fastboot ###
if [ "is${CONFIG_UBOOT_FASTBOOT}" == "isy" ]; then
  [ "is${CONFIG_PREBOOT_BOOTFLOW_SPIUBOOT}" != "isy" ]
  source ${basedir_script_subimg}/uboot/common.bashrc
  source ${basedir_script_subimg}/uboot/emmc.bashrc
fi

### Runtime ###
if [ "has${CONFIG_RUNTIME_FILESYSTEMS}" != "has" ]; then
  ### Kernel/RAMDISK ###
  source ${basedir_script_subimg}/linux_bootimgs/common.bashrc
  source ${basedir_script_subimg}/linux_bootimgs/emmc.bashrc

  ### Filesystems ###
  source ${basedir_script_subimg}/fsimgs/common.bashrc

  system_partition_name="system"
  for item in ${subimg_list}; do
    eval item_name=\$$item
    if [ "${item_name}" == "system" ]; then
      system_partition_name="${item}"
      break;
    fi
  done
  source ${basedir_script_subimg}/fsimgs/emmc.bashrc
fi

#
# Generate EMMC images
#
product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
outdir_product_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/release
outdir_product_release_emmc=${outdir_product_release}/eMMCimg
mkdir -p ${outdir_product_release_emmc}

cat ${outdir_subimg_intermediate}/emmc_image_list \
  | sed -e 's/\(\.subimg\),/\1.gz,/' \
  > ${outdir_product_release_emmc}/emmc_image_list
cp -ad ${outdir_subimg_intermediate}/emmc_part_list ${outdir_product_release_emmc}/.

# Prepare subimg info
emmc_release_subimg_imagelist "preboot" "${subimg_list}"
emmc_release_subimg_imagelist "tee" "${subimg_list}"
emmc_release_subimg_imagelist "tee_recovery" "${subimg_list}"

if [ "is${CONFIG_ANDROID_OS}" == "isy" ]; then
        emmc_release_subimg_imagelist "fastboot" "${subimg_list}"
fi

emmc_release_subimg_imagelist "bootloader" "${subimg_list}"

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  emmc_release_subimg_imagelist "firmware" "${subimg_list}"
fi

emmc_release_subimg_imagelist "key" "${subimg_list}"

if [ "has${CONFIG_RUNTIME_FILESYSTEMS}" != "has" ]; then
  emmc_release_subimg_imagelist "linux_bootimgs" "${subimg_list}"
  emmc_release_subimg_imagelist "system" "${subimg_list}"
fi

if [ "is${CONFIG_UBOOT_FASTBOOT}" == "isy" ]; then
  [ "is${CONFIG_PREBOOT_BOOTFLOW_SPIUBOOT}" != "isy" ]
  emmc_release_subimg_imagelist "fastboot" "${subimg_list}"
fi

if [ "is${CONFIG_BL_FASTLOGO}" == "isy" ]; then
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    if [ -f ${outdir_subimg_intermediate}/fastlogo.subimg ]; then
      cat ${outdir_subimg_intermediate}/fastlogo.subimg | gzip -1 > ${outdir_product_release_emmc}/fastlogo.subimg.gz
    fi
  fi
  if [ "is${CONFIG_GENX_ENABLE}" != "isy" ]; then
    if [ -f ${product_dir}/fastlogo.subimg.gz ]; then
      cp ${product_dir}/fastlogo.subimg.gz ${outdir_product_release_emmc}
      cp ${product_dir}/fastlogo.subimg.gz ${outdir_subimg_intermediate}
      gunzip -f ${outdir_subimg_intermediate}/fastlogo.subimg.gz
    fi
  fi
  emmc_release_subimg_imagelist "fastlogo" "${subimg_list}"
fi

if [ "is${CONFIG_EXT_PREBOOT_BOOTFLOW_AB}" = "isy" ];then
    if [ -f ${product_dir}/misc.subimg.gz ]; then
        cp ${product_dir}/misc.subimg.gz ${outdir_product_release_emmc}
    fi
fi
