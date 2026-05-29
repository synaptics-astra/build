# Bash script: subimage: firmware: emmc

#############
# Functions #
#############

get_image_aligned() {
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

generate_firmware_subimg() {
  ### use genimg to pack all firmware images ###
  params=""

  # SM firmware
  if [ "is${CONFIG_UBOOT_SUBOOT}" = "isy" ]; then
    if [ -f ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_UBOOT_REL_PATH}/sm_fw_en.bin ]; then
      params="$params -i SMFW -d ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_UBOOT_REL_PATH}/sm_fw_en.bin"
    else
      echo "no sm_fw_en.bin under ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_UBOOT_REL_PATH}!!!"
  #    exit 1
    fi
  fi

  if [ "is${CONFIG_BOOTLOADER}" = "isy" ]; then
    if [ -f ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_BL_REL_PATH}/sm_fw_en.bin ]; then
      params="$params -i SMFW -d ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_BL_REL_PATH}/sm_fw_en.bin"
    else
      echo "no sm_fw_en.bin under ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_BL_REL_PATH}!!!"
      if [ "is${CONFIG_BL_SYSTEM_MANAGER}" = "isy" ]; then
        exit 1
      fi
    fi
  fi

  echo "######$params"
  ${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}/genimg -n firmware $params -o ${outfile_firmware_pack}
}

mkdir -p ${outfile_firmware}

generate_firmware_subimg

# Generate subimg
${basedir_tools}/prepend_image_info.sh ${outdir_firmware_release}/${outfile_firmware_pack} ${outfile_firmware_subimg}
