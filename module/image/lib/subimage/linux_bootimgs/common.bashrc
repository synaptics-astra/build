# Bash script: subimage: linux_bootimgs: common

# Directories
outdir_linux_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_LINUX_REL_PATH}

# Output file
outfile_linuxbootimgs_subimg=${outdir_subimg_intermediate}/linux_bootimgs.subimg

#############
# Functions #
#############

pack_boot_imgs() {
  local f_output
  f_output=$1; shift
  f_compress_method=$1; shift

  local kernel_cmdline
  kernel_cmdline=$(cat ${workdir_product_config}/kernel_cmdline)

  local f_ramdisk
  local f_imgdtb

  local dtb_name
  dtb_name=$(echo ${CONFIG_LINUX_DTS} | cut -d , -f 1)
  dtb_name=${dtb_name##*/}

  f_imgdtb="${outdir_linux_release}/${f_compress_method}Image-dtb.${dtb_name}"
  f_ramdisk=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_RUNTIME_REL_PATH}/ramdisk.cpio.xz

  [ -f $f_imgdtb ]
  [ -f $f_ramdisk ]

  local exec2run
  exec2run="${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}/mkbootimg"

  local cmd_args
  cmd_args="--kernel $f_imgdtb"
  cmd_args="$cmd_args --cmdline \"$kernel_cmdline\""
  cmd_args="$cmd_args --base 0x05000000 "
  cmd_args="$cmd_args --ramdisk $f_ramdisk"
  cmd_args="$cmd_args --output $f_output"

  echo $exec2run "$cmd_args"
  eval $exec2run "$cmd_args"

  [ -f $f_output ]
}

gen2_secure_image() {
  local v_image_type
  local f_input
  local f_output

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
    "kernel")
      exec_args="${exec_args} --code-type=5"
      # hardcode for AS390 temporarily
      if [ "x${add_key_store}" != "xy" ]; then
        exec_args="${exec_args} --add-custk-store=0 --add-ersak-store=0"
      else
        exec_args="${exec_args} --add-custk-store=1 --add-ersak-store=1"
      fi
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
  eval ${exec_cmd} "${exec_args}"
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
  exec_args="${exec_args} --workdir-security-keys=${security_keys_path}"
  # Input and output
  exec_args="${exec_args} --in_payload=${f_input} --out_store=${f_output}"

  ### Generate secure image ###
  eval ${exec_cmd} "${exec_args}"
}
