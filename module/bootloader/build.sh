#!/bin/bash

source build/header.rc
source build/chip.rc
source build/security.rc

build_bootloader() {
  local cmd2run

  if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
      opt_flash_type=EMMC
  fi
  if [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
      opt_flash_type=NAND
  fi
  if [ "is${CONFIG_LINUX_OS}" = "isy" ]; then
      opt_bootflow=LINUX
  fi
  if [ "is${CONFIG_ANDROID_OS}" = "isy" ]; then
      opt_bootflow=VERIFIEDBOOT
  fi
  cmd2run="env"

  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_GENX_ENABLE=${CONFIG_GENX_ENABLE}"
  fi

  if [ "is${CONFIG_RDK_SYS}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_RDK_SYS=${CONFIG_RDK_SYS}"
  fi

  if [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_BOOT_PART_SIZE=${CONFIG_NAND_BOOT_PART_SIZE}"
  fi
  if [ "is${CONFIG_NAND_CADENCE}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_NAND_CADENCE=y"
  fi
  if [ "is${CONFIG_NAND_RANDOMIZER}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_NAND_RANDOMIZER=y"
  fi
  cmd2run="${cmd2run} SDK_CROSS_COMPILE=${CONFIG_TOOLCHAIN_BSP}"
  if [ "is${CONFIG_LINUX_ARCH}" = "isarm64" ]; then
      cmd2run="${cmd2run} CPU_ARCH=armv8"
  fi
  cmd2run="${cmd2run} BERLIN_CHIP=${syna_chip_name}"
  cmd2run="${cmd2run} CHIP_VER=${syna_chip_rev}"
  cmd2run="${cmd2run} PLATFORM=${CONFIG_PREBOOT_PLATFORM}"
  cmd2run="${cmd2run} CONFIG_FLASH_TYPE=${opt_flash_type}"
  cmd2run="${cmd2run} CONFIG_BOOTFLOW=${opt_bootflow}"
  cmd2run="${cmd2run} CPUPLL=${CONFIG_BL_CPUPLL}"

  if [ "is${CONFIG_PREBOOT_BOOTFLOW_NR}" = "isy" ];then
    cmd2run="${cmd2run} BOOTFLOW_VER=NR"
    cmd2run="${cmd2run} CONFIG_BL_SYSTEM_AS_ROOT=${CONFIG_BL_SYSTEM_AS_ROOT}"
    cmd2run="${cmd2run} CONFIG_BL_RECOVERY_DTBO=${CONFIG_BL_RECOVERY_DTBO}"
  elif [ "is${CONFIG_PREBOOT_BOOTFLOW_AB}" = "isy" ];then
    cmd2run="${cmd2run} BOOTFLOW_VER=AB"
  else
    cmd2run="${cmd2run} BOOTFLOW_VER=old"
  fi
  if [ "is${CONFIG_BL_VERIFIEDBOOT10}" = "isy" ];then
    cmd2run="${cmd2run} VERIFIEDBOOT_VER=V10"
  fi
  if [ "is${CONFIG_BL_VERIFIEDBOOT20}" = "isy" ];then
    cmd2run="${cmd2run} VERIFIEDBOOT_VER=V20"
  fi
  if [ "is${CONFIG_BL_AVB_1P2_L}" = "isy" ];then
    cmd2run="${cmd2run} AVB_1P2_LAUNCHED=y"
  fi
  if [ "is${CONFIG_BL_PRELOAD_TA}" = "isy" ];then
    cmd2run="${cmd2run} PRELOADTA_ENABLE=y"
  else
    cmd2run="${cmd2run} PRELOADTA_ENABLE=n"
  fi
  if [ "is${CONFIG_TA_KEYMASTER_V4}" = "isy" ];then
    cmd2run="${cmd2run} TA_KEYMASTER_V4=y"
  else
    cmd2run="${cmd2run} TA_KEYMASTER_V4=n"
  fi

  if [ "is${CONFIG_BL_RPMB}" = "isy" ]; then
    cmd2run="${cmd2run} CONFIG_TRUSTZONE_RPMB_FEATURE=y"
  fi
  if [ "is${CONFIG_BL_RPMB_AVB}" = "isy" ]; then
    cmd2run="${cmd2run} CONFIG_BL_RPMB_AVB=y"
  fi
  if [ "is${CONFIG_BL_FASTLOGO}" = "isy" ]; then
    cmd2run="${cmd2run} CONFIG_FASTLOGO=y"
    cmd2run="${cmd2run} BL_FASTLOGO_RESID=${CONFIG_BL_FASTLOGO_RESID}"

    cmd2run="${cmd2run} BL_DISPLAY_MODE=${CONFIG_BL_FASTLOGO_DISPLAY_MODE}"
    if [ "is${CONFIG_BL_FASTLOGO_DISPLAY_MODE}" = "is2" ]; then
      cmd2run="${cmd2run} BL_SECONDARY_RESID=${CONFIG_BL_FASTLOGO_SECONDARY_RESID}"
    fi
  fi
  if [ "is${CONFIG_BL_FUNCTION_BUTTON}" = "isy" ]; then
    cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_ENABLE=y"

    if [ "is${CONFIG_BL_ADC_BUTTON}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_ADC=y"
      cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_ADC_CH=${CONFIG_BL_ADC_CH}"
    fi
    if [ "is${CONFIG_BL_GPIO_BUTTON}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_ADC=n"
      cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_SM_GPIO_PORT=${CONFIG_BL_GPIO_PORT}"
    fi
    if [ "is${CONFIG_BL_ADC_MV_AUXADC10}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_DWC_ADC12B5MSAR=n"
    fi
    if [ "is${CONFIG_BL_ADC_DWC_ADC12B5MSAR}" = "isy" ]; then
      cmd2run="${cmd2run} CONFIG_DWC_ADC12B5MSAR=y"
    fi
    cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_HIGH_LEV_VALID=${CONFIG_BL_HIGH_LEVEL_VALID}"
    cmd2run="${cmd2run} CONFIG_FUNCTION_BUTTON_FASTBOOT=${CONFIG_BL_FASTBOOT_FUNCTION_BUTTON}"

  fi

  if [ "is${CONFIG_BL_PV_COMP}" = "isy" ]; then
    if [ "is${CONFIG_BL_PV_AD5231}" = "isy" ]; then
      cmd2run="${cmd2run} PV_COMP=AD5231"
    fi
    if [ "is${CONFIG_BL_PV_I2C}" = "isy" ]; then
      cmd2run="${cmd2run} PV_COMP=I2C"
    fi
    if [ "is${CONFIG_BL_PV_I2C_NEW}" = "isy" ]; then
      cmd2run="${cmd2run} PV_COMP=I2C_NEW"
    fi
  fi

  if [ "is${CONFIG_BL_SYSTEM_MANAGER}" = "isy" ]; then
    cmd2run="${cmd2run} CONFIG_SM=y"
    cmd2run="${cmd2run} CONFIG_SM_CM3_FW=${CONFIG_SM_CM3_FW}"
    cmd2run="${cmd2run} CONFIG_SM_RAM_TS_DISABLE=${CONFIG_SM_RAM_TS_DISABLE}"
    cmd2run="${cmd2run} CONFIG_SM_RAM_TS_ENABLE=${CONFIG_SM_RAM_TS_ENABLE}"
    cmd2run="${cmd2run} CONFIG_SM_RAM_PARAM_ENABLE=${CONFIG_SM_RAM_PARAM_ENABLE}"
  fi
  cmd2run="${cmd2run} CONFIG_ENABLE_JTAG=${CONFIG_JTAG_ENABLE}"
  cmd2run="${cmd2run} CONFIG_DTB=${CONFIG_BL_DTB}"

  #TODO: remove source code dependency
  cmd2run="${cmd2run} COMM_DIR=${CONFIG_SYNA_SDK_PATH}/boot/common"

  # other fixed options
  cmd2run="${cmd2run} CONFIG_EMMC_V5=y"
  cmd2run="${cmd2run} CONFIG_GPT=y"
  cmd2run="${cmd2run} CONFIG_APB_TIMER_DISABLE=y"
  cmd2run="${cmd2run} DISABLE_CRASH_COUNTER=y"
  cmd2run="${cmd2run} CONFIG_TRUSTZONE=y"
  cmd2run="${cmd2run} CONFIG_PRODUCTION_BUILD=${CONFIG_PRODUCTION_BUILD}"
  cmd2run="${cmd2run} CONFIG_LINUX_SRC_PATH=${CONFIG_LINUX_SRC_PATH}"

  cmd2run="${cmd2run} OUTPUT_DIR=${opt_outdir_intermediate}"

  cmd2run1="${cmd2run} make clean && "
  cmd2run1="${cmd2run1} ${cmd2run} make configure CPUPLL=${CONFIG_BL_CPUPLL}"
  cmd2run1="${cmd2run1} BOOT_TYPE=EMMC_BOOT &&"
  cmd2run1="${cmd2run1} ${cmd2run} make || exit 1"

  pushd ${topdir}/boot/bootloader
  echo $cmd2run1
  eval "$cmd2run1"
  popd
}

genx_secure_image() {
  v_image_type=$1; shift
  in_extras=$1; shift
  in_length=$1; shift
  f_input=$1; shift
  f_output=$1; shift

  ### Check input file ###
  [ -f $f_input ]

  ### Exectuable for generating secure image ###
  if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
    exec_cmd=${security_tools_path}gen_x_secure_image
    [ -x $exec_cmd ]
  else
    exec_cmd=gen_x_secure_image
  fi

  ### Prepare arguments ###
  unset exec_args

  # Other parameters
  exec_args="${exec_args} --chip-name=${syna_chip_name}"
  exec_args="${exec_args} --chip-rev=${syna_chip_rev}"
  exec_args="${exec_args} --img_type=$v_image_type"
  exec_args="${exec_args} --key_type=ree"

  #exec_args="${exec_args} --seg_id=0x00000000"
  #exec_args="${exec_args} --seg_id_mask=0xFFFFFFFF"
  #exec_args="${exec_args} --version=0x00000001"
  #exec_args="${exec_args} --version_mask=0xFFFFFFFF"
  exec_args="${exec_args} --length=$in_length"
  exec_args="${exec_args} --extras=$in_extras"
  exec_args="${exec_args} --workdir-security-tools=${security_tools_path}"

  if [ "x${security_keys_path}" != "x" ]; then
    exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"
  fi

  # Input and output
  exec_args="${exec_args} --in_payload=${f_input} --out_store=${f_output}"

  ### Generate secure image ###
  eval ${exec_cmd} "${exec_args}"
}

gen2_secure_image() {
  v_image_type=$1; shift
  f_input=$1; shift
  f_output=$1; shift

  ### Check input file ###
  [ -f $f_input ]

  ### Exectuable for generating secure image ###
  if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
    exec_cmd=${security_tools_path}gen_secure_image
    [ -x $exec_cmd ]
  else
    exec_cmd=gen_secure_image
  fi

  ### Prepare arguments ###
  unset exec_args

  # Codetype
  case "$v_image_type" in
    "bootloader")
      exec_args="${exec_args} --code-type=5"
      ;;
    *) /bin/false ;;
  esac

  local workdir_security_ver=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_VERSION_PATH}
  if [ -f ${workdir_security_ver}/codetype_5/config ]; then
      exec_args="${exec_args} --security-config-path=${workdir_security_ver}/codetype_5/config"
  fi

  local MARKET_ID=`printf 0x%x ${CONFIG_PREBOOT_MARKET_ID}`
  # Other parameters
  exec_args="${exec_args} --chip-name=${syna_chip_name}"
  exec_args="${exec_args} --chip-rev=${syna_chip_rev}"
  exec_args="${exec_args} --market-id=${MARKET_ID}"
  exec_args="${exec_args} --workdir-security-tools=${security_tools_path}"
  exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"

  # Input and output
  exec_args="${exec_args} --input-file=${f_input} --output-file=${f_output}"

  # Do not add custk and rsa key stores
  # hardcode for AS390 temperaly
  if [ "x${add_key_store}" != "xy" ]; then
    exec_args="${exec_args} --add-custk-store=0"
    exec_args="${exec_args} --add-ersak-store=0"
  else
    exec_args="${exec_args} --add-custk-store=1"
    exec_args="${exec_args} --add-ersak-store=1"
  fi

  ### Generate secure image ###
  eval ${exec_cmd} "${exec_args}"
}

########
# Main #
########
module_topdir=${topdir}/boot/bootloader
opt_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_BL_REL_PATH}
opt_outdir_intermediate=${opt_outdir_release}/intermediate
mkdir -p ${opt_outdir_intermediate}

if [ $clean -eq 1 ]; then
    rm -rf ${module_topdir}/out/ ${opt_outdir_intermediate}/bootloader_raw.bin ${opt_outdir_release}/bootloader_en.bin
    exit 0
fi

if [ "is${CONFIG_BL_SYSTEM_MANAGER}" = "isy" ]; then
    if [ "is${CONFIG_RDK_SYS}" != "isy" ]; then
        ### Build system manager ###
        build/module/bootloader/build_sm.sh ${1}
    fi
fi

if [ -f ${module_topdir}/BUILD_NUMBER ]; then
    export SDK_RELEASE_BUILD_NUMBER=`cat ${module_topdir}/BUILD_NUMBER`
else
    export SDK_RELEASE_BUILD_NUMBER="source_code"
fi

### Build bootloader ###
build_bootloader

### Check results ###
[ -f ${opt_outdir_intermediate}/output_bootloader/bootloader.bin ]
cp -f ${opt_outdir_intermediate}/output_bootloader/bootloader.bin ${opt_outdir_intermediate}/bootloader_raw.bin
sha256sum ${opt_outdir_intermediate}/bootloader_raw.bin

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    [ -f ${opt_outdir_intermediate}/output_sm/bin/sm.bin ]
    cp -f ${opt_outdir_intermediate}/output_sm/bin/sm.bin ${opt_outdir_intermediate}/sm_fw_raw.bin
    sha256sum ${opt_outdir_intermediate}/sm_fw_raw.bin

    dd if=/dev/zero of=${opt_outdir_intermediate}/bootloader_prepending.bin bs=1 count=48
    cat ${opt_outdir_intermediate}/bootloader_prepending.bin ${opt_outdir_intermediate}/bootloader_raw.bin > ${opt_outdir_intermediate}/bootloader_prepending_raw.bin
    mv ${opt_outdir_intermediate}/bootloader_prepending_raw.bin ${opt_outdir_intermediate}/bootloader_raw.bin
fi

### Check raw binaries ###
[ -f ${opt_outdir_intermediate}/bootloader_raw.bin ]
ls -l ${opt_outdir_intermediate}/*.bin

if [ "is${CONFIG_PREBOOT_BOOTFLOW_VERSION}" = "isold" ]; then
  ### pack with fastboot by using GIH
  if [ "x${opt_outdir_uboot_intermediate}" = "x" ]; then
    echo "the path of uboot doesn't exist!!!"
    exit 1
  fi
  [ -f ${opt_outdir_uboot_intermediate}/uboot_raw.bin ]
  gen_cmd=${opt_bindir_host}/genimg
  gen_args="-n bootloader -V 0 -v 1"
  gen_args="${gen_args} -i BTLR -d ${opt_outdir_intermediate}/bootloader_raw.bin -a 0x000000007f804000"
  gen_args="${gen_args} -i FSBT -d ${opt_outdir_uboot_intermediate}/uboot_raw.bin -a 0x000000007f804000"
  gen_args="${gen_args} -o ${opt_outdir_intermediate}//bootloader_image_list.img"

  eval ${gen_cmd} "${gen_args}"

  ### Sign BOOTLOADER ###
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    cp -ad ${opt_outdir_intermediate}/bootloader_image_list.img ${opt_outdir_release}/bootloader_en.bin
  else
    gen2_secure_image "bootloader" ${opt_outdir_intermediate}/bootloader_image_list.img ${opt_outdir_release}/bootloader_en.bin
  fi
else
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    ${security_tools_path}in_extras.py "SM_FW" ${opt_outdir_release}/in_sm_fw_extras.bin 0x00000001
    ${security_tools_path}in_extras.py "BOOT_LOADER" ${opt_outdir_release}/in_boot_loader_extras.bin 0x00000001
    genx_secure_image "SM_FW" ${opt_outdir_release}/in_sm_fw_extras.bin 0x0 ${opt_outdir_intermediate}/sm_fw_raw.bin ${opt_outdir_release}/sm_fw_en.bin
    genx_secure_image "BOOT_LOADER" ${opt_outdir_release}/in_boot_loader_extras.bin 0x0 ${opt_outdir_intermediate}/bootloader_raw.bin ${opt_outdir_release}/bootloader_en.bin
  else
    gen2_secure_image "bootloader" ${opt_outdir_intermediate}/bootloader_raw.bin ${opt_outdir_release}/bootloader_en.bin
  fi
fi
