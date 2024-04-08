# Bash script: subimage: fastlogo: emmc

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

product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
opt_outdir_release=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/fastlogo
opt_outdir_intermediate=${opt_outdir_release}/intermediate
mkdir -p ${opt_outdir_intermediate}

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  if [ -f ${product_dir}/fastlogo.subimg.gz ]; then
    cp ${product_dir}/fastlogo.subimg.gz ${opt_outdir_intermediate}
    gunzip ${opt_outdir_intermediate}/fastlogo.subimg.gz
    mv ${opt_outdir_intermediate}/fastlogo.subimg ${opt_outdir_intermediate}/fastlogo_payload.subimg
  fi

  if [ -f ${opt_outdir_intermediate}/fastlogo_payload.subimg ]; then
    ${security_tools_path}in_extras.py "FASTLOGO" ${opt_outdir_intermediate}/in_fastlogo_extras.bin 0x00000001
    genx_secure_image "FASTLOGO" ${opt_outdir_intermediate}/in_fastlogo_extras.bin 0x0 ${opt_outdir_intermediate}/fastlogo_payload.subimg ${opt_outdir_release}/fastlogo_en.subimg
  fi
fi

# Generate subimg
${basedir_tools}/prepend_image_info.sh ${opt_outdir_release}/fastlogo_en.subimg ${outfile_fastlogo_subimg}
