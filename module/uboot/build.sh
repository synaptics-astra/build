#!/bin/bash

source build/header.rc
source build/chip.rc
source build/security.rc

echo "u-boot build script called"

build_uboot() {
  pushd ${topdir}/boot/${CONFIG_UBOOT_SRC_PATH}
  local cmd2run

  cmd2run="env"
  eval "$cmd2run make mrproper"

  cmd2run="${cmd2run} KBUILD_OUTPUT=${opt_outdir_intermediate}/output_uboot"
  cmd2run="${cmd2run} CROSS_COMPILE=${CONFIG_TOOLCHAIN_BSP}"
  cmd2run="${cmd2run}"

  eval "CONFIG_RDK_SYS=${CONFIG_RDK_SYS} $cmd2run make mrproper"
  eval "CONFIG_RDK_SYS=${CONFIG_RDK_SYS} $cmd2run make ${CONFIG_UBOOT_DEFCONFIG} -j${CONFIG_CPU_NUMBER}"
  eval "CONFIG_RDK_SYS=${CONFIG_RDK_SYS} $cmd2run make EXT_DTB=arch/${CONFIG_UBOOT_ARCH}/dts/${CONFIG_UBOOT_DTS}.dtb -j24"
  popd
}
#############
# Functions #
#############

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
    "fastboot")
      exec_args="${exec_args} --code-type=5"
      exec_args="${exec_args} --add-custk-store=0 --add-ersak-store=0"
      ;;
    "uboot")
      exec_args="${exec_args} --code-type=15"
      ;;
    "usbboot")
      exec_args="${exec_args} --code-type=15"
      exec_args="${exec_args} --usb-boot=1"
      ;;
    "uboot_suboot")
      exec_args="${exec_args} --code-type=5"
      exec_args="${exec_args} --add-custk-store=0 --add-ersak-store=0"
      ;;
    *) /bin/false ;;
  esac

  local MARKET_ID=`printf 0x%x ${CONFIG_PREBOOT_MARKET_ID}`
  # Other parameters
  exec_args="${exec_args} --chip-name=${syna_chip_name}"
  exec_args="${exec_args} --chip-rev=${syna_chip_rev}"
  exec_args="${exec_args} --market-id=${MARKET_ID}"
  exec_args="${exec_args} --workdir-security-tools=${security_tools_path}"
  exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"

  # Input and output
  exec_args="${exec_args} --input-file=${f_input} --output-file=${f_output}"

  ### Generate secure image ###
  echo **** ${exec_cmd} "${exec_args}"
  eval ${exec_cmd} "${exec_args}"
}

genx_secure_image() {
  v_image_type=$1; shift
  in_key_type=$1; shift
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
  exec_args="${exec_args} --key_type=${in_key_type}"

  #exec_args="${exec_args} --seg_id=0x00000000"
  #exec_args="${exec_args} --seg_id_mask=0xFFFFFFFF"
  #exec_args="${exec_args} --version=0x00000001"
  #exec_args="${exec_args} --version_mask=0xFFFFFFFF"
  exec_args="${exec_args} --length=$in_length"
  exec_args="${exec_args} --extras=$in_extras"
  exec_args="${exec_args} --workdir-security-tools=${security_tools_path}"
  exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"

  # Input and output
  exec_args="${exec_args} --in_payload=${f_input} --out_store=${f_output}"

  ### Generate secure image ###
  # echo @@@@ ${exec_cmd} "${exec_args}"
  eval ${exec_cmd} "${exec_args}"
}

get_image_aligned() {
  local f_input
  local align_size

  f_input=$1; shift
  align_size=$1; shift

  ### Check input file ###
  [ -f $f_input ]

  f_size=`stat -c %s ${f_input}`
  append_size=`expr ${align_size} - ${f_size} % ${align_size}`

  if [ ${append_size} -lt ${align_size} ]; then
    dd if=/dev/zero of=${f_input} bs=1 seek=${f_size} count=${append_size} conv=notrunc
  fi
}

get_erom_path()
{
  prebuild_dir=$1
  prebuild_dir="${prebuild_dir}/${syna_chip_name}"
  prebuild_dir="${prebuild_dir}/${syna_chip_rev}"
  prebuild_dir="${prebuild_dir}/${CONFIG_PREBOOT_MARKET_ID}"
  prebuild_dir="${prebuild_dir}/bootflow"
  if [ "is${CONFIG_PREBOOT_BOOTFLOW_NR}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/NR"
  elif [ "is${CONFIG_PREBOOT_BOOTFLOW_AB}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/AB"
  else
    /bin/false
  fi
  if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/EMMC"
  elif [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/NAND"
    if [ "is${CONFIG_NAND_RANDOMIZER}" = "isy" ]; then
      prebuild_dir="${prebuild_dir}/randomizer_y"
    else
      prebuild_dir="${prebuild_dir}/randomizer_n"
    fi
  else
    /bin/false
  fi
  if [ "is${CONFIG_FASTBOOT_FLOW}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/fastboot_y"
  else
    prebuild_dir="${prebuild_dir}/fastboot_n"
  fi

  echo ${prebuild_dir}
}

get_sysinit_path()
{
  prebuild_dir=$1
  prebuild_dir="${prebuild_dir}/${syna_chip_name}"
  prebuild_dir="${prebuild_dir}/${syna_chip_rev}"
  prebuild_dir="${prebuild_dir}/${CONFIG_PREBOOT_MARKET_ID}"
  prebuild_dir="${prebuild_dir}/hwinit"
  prebuild_dir="${prebuild_dir}/${CONFIG_PREBOOT_DDR_TYPE}"
  prebuild_dir="${prebuild_dir}/${CONFIG_PREBOOT_MEMORY_SIZE}"
  prebuild_dir="${prebuild_dir}/${CONFIG_PREBOOT_MEMORY_SPEED}"
  prebuild_dir="${prebuild_dir}/${CONFIG_PREBOOT_MEMORY_VARIANT}"
  if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/EMMC"
  elif [ "is${CONFIG_IMAGE_NAND}" = "isy" ]; then
    prebuild_dir="${prebuild_dir}/NAND"
  else
    /bin/false
  fi

  echo ${prebuild_dir}
}

gen_spi_combo() {
  # Parse arguments
  local f_uboot_en
  local f_spi_combo

  f_uboot_en=$1; shift
  f_spi_combo=$1; shift

  # Related source binaries
  local f_erom
  local f_sysinit
  local f_tsm
  local f_ddrphyfw

  if [ -d ${CONFIG_SYNA_SDK_PATH}/boot/preboot/prebuilts ]; then
    base_dir=${CONFIG_SYNA_SDK_PATH}/boot/preboot/prebuilts
    f_erom=$(get_erom_path ${base_dir})
    f_erom=${f_erom}/erom.bin
    f_tsm=$(get_erom_path ${base_dir})
    f_tsm=${f_tsm}/tsm.bin
    f_sysinit=$(get_sysinit_path ${base_dir})
    f_sysinit=${f_sysinit}/sysinit_en.bin
    if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
      f_ddrphyfw=$(get_sysinit_path ${base_dir})
      f_ddrphyfw=${f_ddrphyfw}/ddrphy.bin
      echo $f_ddrphyfw
    fi
  else
    f_erom=${opt_workdir_preboot_release}/erom.bin
    f_sysinit=${opt_workdir_preboot_release}/sysinit_en.bin
    f_tsm=${opt_workdir_preboot_release}/tsm.bin
    if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
      f_ddrphyfw=${opt_workdir_preboot_release}/ddrphy.bin
      echo $f_ddrphyfw
    fi
  fi

  [ -f $f_erom ]
  [ -f $f_sysinit ]
  [ -f $f_tsm ]
  if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
    [ -f $f_ddrphyfw ]
  fi

  # Generate combo
  dd if=/dev/zero bs=1024 count=1 > $f_spi_combo
  if [ "${syna_chip_name}" = "bg4ct" ]; then
    cat $f_erom $f_sysinit $f_tsm >> $f_spi_combo
    get_image_aligned $f_spi_combo 184320
    cat $f_uboot_en >> $f_spi_combo
  else
    if [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ]; then
      cat $f_erom $f_sysinit $f_ddrphyfw $f_uboot_en $f_tsm >> $f_spi_combo
    else
      cat $f_erom $f_sysinit $f_uboot_en $f_tsm >> $f_spi_combo
    fi
  fi
}

gen_x_spi_combo() {
  # Parse arguments
  local f_uboot_en
  local f_spi_combo

  f_uboot_en=$1; shift
  f_spi_combo=$1; shift

  # Related source binaries
  f_K0_BOOT_store=${opt_workdir_preboot_release}/K0_BOOT_store.bin
  f_K0_TEE_store=${opt_workdir_preboot_release}/K0_TEE_store.bin
  f_K1_BOOT_A_store=${opt_workdir_preboot_release}/K1_BOOT_A_store.bin
  f_K1_BOOT_B_store=${opt_workdir_preboot_release}/K1_BOOT_B_store.bin
  f_K1_TEE_A_store=${opt_workdir_preboot_release}/K1_TEE_A_store.bin
  f_EROM=${opt_workdir_preboot_release}/erom.bin
  f_K0_REE_store=${opt_workdir_preboot_release}/K0_REE_store.bin
  f_BCM_Kernel=${opt_workdir_preboot_release}/bcm_kernel.bin
  f_K1_TEE_B_store=${opt_workdir_preboot_release}/K1_TEE_B_store.bin
  f_K1_TEE_C_store=${opt_workdir_preboot_release}/K1_TEE_C_store.bin
  f_K1_TEE_D_store=${opt_workdir_preboot_release}/K1_TEE_D_store.bin
  f_K1_REE_A_store=${opt_workdir_preboot_release}/K1_REE_A_store.bin
  f_K1_REE_B_store=${opt_workdir_preboot_release}/K1_REE_B_store.bin
  f_K1_REE_C_store=${opt_workdir_preboot_release}/K1_REE_C_store.bin
  f_K1_REE_D_store=${opt_workdir_preboot_release}/K1_REE_D_store.bin
  f_SCS_DATA_PARAM=${opt_workdir_preboot_release}/scs_data_param.sign
  f_SCS_DATA_UNCHECKED=${opt_workdir_preboot_release}/scs_data_unchecked.bin
  f_BOOT_MONITOR=${opt_workdir_preboot_release}/boot_monitor.bin
  f_SYS_INIT=${opt_workdir_preboot_release}/sysinit_en.bin
  if [ "is${syna_chip_name}" = "isplatypus" ] || [ "is${syna_chip_name}" = "ismyna2" ]; then
    f_DDRPHY=${opt_workdir_preboot_release}/ddrphy.bin
  elif [ "is${CONFIG_PREBOOT_DDR_PHY_FW}" = "isy" ] && [ "is${syna_chip_name}" = "isdolphin" ]; then
    f_DDRPHY=${opt_workdir_preboot_release}/ddrphy_en.bin
    cat ${opt_workdir_preboot_release}/gen3_ddr_phy_fw_0.bin > $f_DDRPHY
    cat ${opt_workdir_preboot_release}/gen3_ddr_phy_fw_1.bin >> $f_DDRPHY
  fi

  f_MINILOADER=${opt_workdir_preboot_release}/miniloader_en.bin


  [[ -f $f_K0_BOOT_store && -f $f_K0_TEE_store && -f $f_K1_BOOT_A_store && -f $f_K1_BOOT_B_store && -f $f_K1_TEE_A_store && -f $f_EROM && -f $f_K0_REE_store && -f $f_BCM_Kernel && -f $f_K1_TEE_B_store && -f $f_K1_TEE_C_store && -f $f_K1_TEE_D_store && -f $f_K1_REE_A_store && -f $f_K1_REE_B_store && -f $f_K1_REE_C_store && -f $f_K1_REE_D_store && -f $f_SCS_DATA_PARAM && -f $f_SCS_DATA_UNCHECKED && -f $f_BOOT_MONITOR && -f $f_SYS_INIT && -f $f_DDRPHY && -f $f_MINILOADER && -f $f_uboot_en ]]

  # Pack binaries
  dd if=/dev/zero bs=1024 count=1 > $f_spi_combo
  cat $f_K0_BOOT_store >> $f_spi_combo
  cat $f_K0_TEE_store >> $f_spi_combo
  cat $f_K1_BOOT_A_store >> $f_spi_combo
  cat $f_K1_BOOT_B_store >> $f_spi_combo
  cat $f_K1_TEE_A_store >> $f_spi_combo
  cat $f_EROM >> $f_spi_combo
  cat $f_K0_REE_store >> $f_spi_combo
  cat $f_BCM_Kernel >> $f_spi_combo
  cat $f_K1_TEE_B_store >> $f_spi_combo
  cat $f_K1_TEE_C_store >> $f_spi_combo
  cat $f_K1_TEE_D_store >> $f_spi_combo
  cat $f_K1_REE_A_store >> $f_spi_combo
  cat $f_K1_REE_B_store >> $f_spi_combo
  cat $f_K1_REE_C_store >> $f_spi_combo
  cat $f_K1_REE_D_store >> $f_spi_combo
  cat $f_SCS_DATA_PARAM >> $f_spi_combo
  cat $f_SCS_DATA_UNCHECKED >> $f_spi_combo
  cat $f_BOOT_MONITOR >> $f_spi_combo
  cat $f_SYS_INIT >> $f_spi_combo
  cat $f_DDRPHY >> $f_spi_combo
  cat $f_MINILOADER >> $f_spi_combo

  preboot_size=`stat -c %s ${f_spi_combo}`
  padding_size=$[558668 - $preboot_size]


  f_PADDING=${opt_workdir_preboot_release}/dummy.bin

  dd if=/dev/zero of=$f_PADDING bs=1 count=$padding_size

  cat $f_PADDING >> $f_spi_combo
  cat $f_uboot_en >> $f_spi_combo
}

gen_nocs_spi_combo() {
  # Parse arguments
  local f_uboot_en
  local f_spi_combo

  f_uboot_en=$1; shift
  f_spi_combo=$1; shift

  # Related source binaries
  local f_erom
  local f_sysinit
  local f_tsm

  f_erom=${opt_workdir_preboot_release}/real_erom.subimg
  f_sysinit=${opt_workdir_preboot_release}/sysinit.subimg
  f_bm=${opt_workdir_preboot_release}/bm.subimg
  f_scs=${opt_workdir_preboot_release}/scs_unchecked_area
  f_hw_init=${opt_workdir_preboot_release}/hw_init_table.subimg
  f_bk1_bk=${opt_workdir_preboot_release}/real_bkl_bk.subimg

  [ -f $f_erom ]
  [ -f $f_sysinit ]
  [ -f $f_bm ]
  [ -f $f_uboot_en ]
  [ -f $f_bk1_bk ]

  # Generate combo
  dd if=/dev/zero bs=1024 count=1 > $f_spi_combo
  if [ "${syna_chip_name}" = "bg4ct" ]; then
    cat $f_erom $f_sysinit $f_tsm >> $f_spi_combo
    get_image_aligned $f_spi_combo 184320
    cat $f_uboot_en >> $f_spi_combo
  else
    if [ "${syna_chip_name}" = "as390" ]; then
      echo "###################################[refined spi flow for as390]####################"
      cat $f_hw_init \
	      $f_erom \
	      $f_scs \
	      $f_bm \
	      $f_sysinit \
	      $f_uboot_en \
	      $f_erom \
	      $f_erom \
	      $f_bk1_bk >> $f_spi_combo
    else
      cat $f_erom $f_sysinit $f_uboot_en $f_tsm >> $f_spi_combo
    fi
  fi
}

########
# Main #
########

opt_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_UBOOT_REL_PATH}
opt_outdir_intermediate=${opt_outdir_release}/intermediate
opt_workdir_preboot_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_PREBOOT_REL_PATH}/intermediate/release

if [ "is${CONFIG_UBOOT_FASTBOOT}" != "isy" ] && [ "is${CONFIG_UBOOT_SPIUBOOT}" != "isy" ] && [ "is${CONFIG_UBOOT_SUBOOT}" != "isy" ]; then
  echo "none U-Boot image is enabled!"
  exit 0
fi

if [ "is${CONFIG_UBOOT_FASTBOOT}" == "isy" ]; then
  ### update dts memory map of fastboot as per oem_setting.cfg ###
  tee_topdir=${topdir}/tee/tee
  uboot_topdir=${topdir}/boot/${CONFIG_UBOOT_SRC_PATH}
  tz_memlayout=${CONFIG_TZK_MEM_LAYOUT}
  tz_boot_param_value_dir=${tee_topdir}/products/${syna_chip_name}/${tz_memlayout}
  fastboot_dts=${uboot_topdir}/arch/${CONFIG_UBOOT_ARCH}/dts/${CONFIG_UBOOT_DTS}.dts
  system_start=$(awk '/system/{getline;getline;print $3}' $tz_boot_param_value_dir/oem_setting.cfg | sed "s/\",$//;s/^\"0x//")
  system_size=$(awk '/system/{getline;getline;getline;print $3}' $tz_boot_param_value_dir/oem_setting.cfg | sed "s/\"$//;s/^\"0x//")
  val_system_start=$((16#${system_start}))
  val_system_size=$((16#${system_size}))
  #echo "val_system_start" $val_system_start
  #echo "val_system_size" $val_system_size
  memmap_start=$(printf 0x%x $val_system_start)
  memmap_size=$(printf 0x%x $val_system_size)
  #echo "memmap_start" $memmap_start
  #echo "memmap_size" $memmap_size
  sed -i "/device_type/{n;s/[^ ]*[^ ]/${memmap_start}/4;s/[^ ]*[^ ]/${memmap_size}>;/6}" ${fastboot_dts}
fi

if [ $clean -eq 1 ]; then
  rm -rf ${opt_outdir_intermediate}/output_uboot/u-boot.bin  ${opt_outdir_intermediate}/uboot_raw.bin
  exit 0
fi

### Build SM ###
if [ "is${CONFIG_UBOOT_SUBOOT}" = "isy" ]; then
  if [ "is${CONFIG_BL_SYSTEM_MANAGER}" = "isy" ]; then
    ### Build system manager ###
    echo "${1}"
    . build/module/bootloader/build_sm.sh ${1}

    if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
      [ -f ${opt_outdir_intermediate}/output_sm/bin/sm.bin ]
      cp -f ${opt_outdir_intermediate}/output_sm/bin/sm.bin ${opt_outdir_intermediate}/sm_fw_raw.bin
      sha256sum ${opt_outdir_intermediate}/sm_fw_raw.bin

      ${security_tools_path}in_extras.py "SM_FW" ${opt_outdir_release}/in_sm_fw_extras.bin 0x00000001
      genx_secure_image "SM_FW" "ree" ${opt_outdir_release}/in_sm_fw_extras.bin 0x0 ${opt_outdir_intermediate}/sm_fw_raw.bin ${opt_outdir_release}/sm_fw_en.bin
    fi
  fi
fi

### Build uboot###
build_uboot

### Install to destination directory ###
[ -f ${opt_outdir_intermediate}/output_uboot/u-boot.bin ]
cp -ad ${opt_outdir_intermediate}/output_uboot/u-boot.bin ${opt_outdir_intermediate}/uboot_raw.bin

### Check results ###
[ -f ${opt_outdir_intermediate}/uboot_raw.bin ]
sha256sum ${opt_outdir_intermediate}/uboot_raw.bin


### Check raw binaries ###
ls -l ${opt_outdir_intermediate}/*.bin

if [ "is${CONFIG_UBOOT_FASTBOOT}" == "isy" ]; then
  ### FASTBOOT takes 'uboot_en.bin' directly ###
  ### Sign fastboot ###
 if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    ${security_tools_path}in_extras.py "FASTBOOT" ${opt_outdir_release}/in_uboot_extras.bin 0x00000000

    ### Header aligns to 64 Byte ###
    dd if=/dev/zero of=${opt_outdir_intermediate}/uboot_raw_prepending.bin bs=1 count=48
    cat ${opt_outdir_intermediate}/uboot_raw_prepending.bin ${opt_outdir_intermediate}/uboot_raw.bin > ${opt_outdir_intermediate}/uboot_prepending_raw.bin
    mv ${opt_outdir_intermediate}/uboot_prepending_raw.bin ${opt_outdir_intermediate}/uboot_raw.bin

    genx_secure_image "FASTBOOT" "ree" ${opt_outdir_release}/in_uboot_extras.bin 0x0 ${opt_outdir_intermediate}/uboot_raw.bin ${opt_outdir_release}/uboot_en.bin
  else
    gen2_secure_image "fastboot" ${opt_outdir_intermediate}/uboot_raw.bin ${opt_outdir_release}/uboot_en.bin
  fi

  echo "FASTBOOT Image Generation"
  cp -ad ${opt_outdir_release}/uboot_en.bin ${opt_outdir_release}/fastboot_en.bin
elif [ "is${CONFIG_IMAGE_USBBOOT}" = "isy" ]; then
  gen2_secure_image "usbboot" ${opt_outdir_intermediate}/uboot_raw.bin ${opt_outdir_release}/uboot_en.bin

  echo "USBBOOT Image Generation"
elif [ "is${CONFIG_UBOOT_SUBOOT}" = "isy" ]; then
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    dd if=/dev/zero of=${opt_outdir_intermediate}/uboot_prepending.bin bs=1 count=48
    cat ${opt_outdir_intermediate}/uboot_prepending.bin ${opt_outdir_intermediate}/uboot_raw.bin > ${opt_outdir_intermediate}/uboot_prepending_raw.bin

    ${security_tools_path}in_extras.py "BOOT_LOADER" ${opt_outdir_release}/in_boot_loader_extras.bin 0x00000001
    genx_secure_image "BOOT_LOADER" "ree" ${opt_outdir_release}/in_boot_loader_extras.bin 0x0 ${opt_outdir_intermediate}/uboot_prepending_raw.bin ${opt_outdir_release}/uboot_en.bin
  else
    gen2_secure_image "uboot_suboot" ${opt_outdir_intermediate}/uboot_raw.bin ${opt_outdir_release}/uboot_en.bin
  fi

  echo "U-Boot SUBOOT Image Generation"
else
  ### Sign U-boot and Generate SPI U-boot combo ###
  ### Sign uboot ###
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
     ${security_tools_path}in_extras.py "UBOOT" ${opt_outdir_release}/in_uboot_extras.bin 0x00000000
     genx_secure_image "UBOOT" "boot" ${opt_outdir_release}/in_uboot_extras.bin 0x0 ${opt_outdir_intermediate}/uboot_raw.bin ${opt_outdir_release}/uboot_en.bin
  else
     gen2_secure_image "uboot" ${opt_outdir_intermediate}/uboot_raw.bin ${opt_outdir_release}/uboot_en.bin
  fi

  echo "SPI_Uboot Image Generation"
  if [ "${CONFIG_PREBOOT_PROFILE}" = "nocs" ]; then
    echo "---------------NOCS SPI image----------------"
    gen_nocs_spi_combo ${opt_outdir_release}/uboot_en.bin ${opt_outdir_release}/spi_uboot_en.bin
  else
    if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
      gen_x_spi_combo ${opt_outdir_release}/uboot_en.bin ${opt_outdir_release}/spi_uboot_en.bin
    else
      gen_spi_combo ${opt_outdir_release}/uboot_en.bin ${opt_outdir_release}/spi_uboot_en.bin
    fi
  fi
  echo "SPI U-boot combo: ${opt_outdir_release}/spi_uboot_en.bin"
fi
