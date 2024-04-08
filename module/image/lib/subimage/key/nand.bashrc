# Bash script: subimage: key: emmc


#############
# Functions #
#############
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
  exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"

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
    "android_key")
      exec_args="${exec_args} --code-type=5"
      exec_args="${exec_args} --workdir-security-tools=${security_tools_path}"
      exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"
      exec_args="${exec_args} --add-custk-store=0 --add-ersak-store=0"
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
  exec_args="${exec_args} --chip-rev=${sync_chip_rev}"
  exec_args="${exec_args} --market-id=${MARKET_ID}"

  if [ "is${CONFIG_PACKAGING_USBBOOT}" = "isy" ]; then
    exec_args="${exec_args} --usb-boot=1"
  fi

  # Input and output
  exec_args="${exec_args} --input-file=${f_input} --output-file=${f_output}"

  ### Generate secure image ###
  eval ${exec_cmd} "${exec_args}"
}

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

# according to discuss with hongguang and get compatible between bg4ct and bg5ct(and future chip)
# below layout will be used
# ------oemcustkey and oemextraraskey ------ 16K
# ------android oem verity key ------ 16K
# ------android usr verity key ------ 16K
# on bg4ct, it will be stored at 240K of boot partition
# on bg5ct and future chip, it will be stored at user partition "key_1st" and "key_2nd"

if [ "is${CONFIG_GENX_ENABLE}" != "isy" ]; then
  f_oemcustkey=${workdir_security_keys}/mid-$(printf %08x ${CONFIG_PREBOOT_MARKET_ID})/codetype_5/custk.keystore
  f_oemextrarsakey=${workdir_security_keys}/mid-$(printf %08x ${CONFIG_PREBOOT_MARKET_ID})/codetype_5/extrsa.keystore

  [ -f $f_oemcustkey ]
  [ -f $f_oemextrarsakey ]

  echo "/bin/cp $f_oemcustkey ${opt_outdir_release}/oemcustkey"
  /bin/cp $f_oemcustkey ${outdir_subimg_intermediate}/oemcustkey
  /bin/cp $f_oemextrarsakey ${outdir_subimg_intermediate}/oemextrsakey

  get_image_aligned ${outdir_subimg_intermediate}/oemcustkey 1024
  cat ${outdir_subimg_intermediate}/oemcustkey ${outdir_subimg_intermediate}/oemextrsakey > ${outfile_key_subimg}
  get_image_aligned ${outfile_key_subimg} 16384
  rm ${outdir_subimg_intermediate}/oemcustkey ${outdir_subimg_intermediate}/oemextrsakey
fi

android_tool_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}/android_key
f_androidoemkey=${android_tool_dir}/oem_verity_key
f_androidusrkey=${android_tool_dir}/usr_verity_key

if [ "is${CONFIG_ANDROID_OS}" = "isy" ]; then
  [ -f $f_androidoemkey ]
  [ -f $f_androidusrkey ]
fi

#FIXME: for linuxsdk, it is over
if [ "is${CONFIG_ANDROID_OS}" = "isy" ]; then
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    dd if=/dev/zero of=${outfile_key_subimg} bs=1 count=16384
    ${security_tools_path}in_extras.py "AVB_KEYS" ${outdir_subimg_intermediate}/in_avb_keys.bin 0x00000001
    genx_secure_image "AVB_KEYS" ${outdir_subimg_intermediate}/in_avb_keys.bin 0x0 ${f_androidoemkey} ${outdir_subimg_intermediate}/androidoemkey_en
    genx_secure_image "AVB_KEYS" ${outdir_subimg_intermediate}/in_avb_keys.bin 0x0 ${f_androidusrkey} ${outdir_subimg_intermediate}/androidusrkey_en
    get_image_aligned ${outdir_subimg_intermediate}/androidoemkey_en 16384
    get_image_aligned ${outdir_subimg_intermediate}/androidusrkey_en 16384

    cat ${outdir_subimg_intermediate}/androidoemkey_en >> ${outfile_key_subimg}
    cat ${outdir_subimg_intermediate}/androidusrkey_en >> ${outfile_key_subimg}

    rm ${outdir_subimg_intermediate}/androidoemkey_en ${outdir_subimg_intermediate}/androidusrkey_en ${outdir_subimg_intermediate}/in_avb_keys.bin
  else
    gen2_secure_image "android_key" ${f_androidoemkey} ${outdir_subimg_intermediate}/androidoemkey_en
    gen2_secure_image "android_key" ${f_androidusrkey} ${outdir_subimg_intermediate}/androidusrkey_en
    get_image_aligned ${outdir_subimg_intermediate}/androidoemkey_en 16384
    get_image_aligned ${outdir_subimg_intermediate}/androidusrkey_en 16384

    cat ${outdir_subimg_intermediate}/androidoemkey_en >> ${outfile_key_subimg}
    cat ${outdir_subimg_intermediate}/androidusrkey_en >> ${outfile_key_subimg}

    rm ${outdir_subimg_intermediate}/androidoemkey_en ${outdir_subimg_intermediate}/androidusrkey_en
  fi
else  ### TODO: no key subimge for Linux profiles  ###
  if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
    echo "00000000" > ${outfile_key_subimg}
  fi
fi

