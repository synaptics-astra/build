# Bash script: subimage: preload_ta: emmc

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

generate_preload_ta_subimg() {
  ### use genimg to pack all preload TAs ###
  params=""

  if [ "is${CONFIG_BL_TA_FASTLOGO}" = "isy" ]; then
    if [ -e ${input_ta_path}/libfastlogo.ta ]; then
      params="$params -i LOGO -d ${input_ta_path}/libfastlogo.ta/libfastlogo.ta"
    else
      echo "no libfastlogo.ta under ${input_ta_path}!!!"
      exit 1
    fi
  fi

  if [ "is${CONFIG_BL_TA_KEYMASTER}" = "isy" ]; then
    if [ -e ${input_ta_path}/libgencrypto.ta ]; then
      params="$params -i CYPT -d ${input_ta_path}/libgencrypto.ta/libgencrypto.ta"
    else
      echo "no libgencrypto.ta under ${input_ta_path}!!!"
      exit 1
    fi
  fi

  if [ "is${CONFIG_BL_TA_DHUB}" = "isy" ]; then
    if [ -e ${input_ta_path}/libdhub.ta ]; then
      params="$params -i DHUB -d ${input_ta_path}/libdhub.ta/libdhub.ta"
    else
      echo "no libdhub.ta under ${input_ta_path}!!!"
      exit 1
    fi
  fi

  echo "######$params"
  ${CONFIG_SYNA_SDK_OUT_HOST_REL_PATH}/genimg -n preload_ta -A 4096 $params -o ${preload_ta_subimg}
  rm ${outdir_preload_ta}/*.header
  rm ${outdir_preload_ta}/*.header.filler
}

mkdir -p ${outdir_preload_ta}
generate_preload_ta_subimg

[ -f ${preload_ta_subimg} ]
[ -f ${outfile_bootloader_subimg} ]

# apend preload tas to 512B aligned address
get_image_aligned ${outfile_bootloader_subimg} 512

# Packaging preloadta image
cat ${preload_ta_subimg} >> ${outfile_bootloader_subimg}
