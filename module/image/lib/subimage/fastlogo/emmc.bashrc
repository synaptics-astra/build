# Bash script: subimage: fastlogo: emmc

product_dir=${CONFIG_SYNA_SDK_PRODUCT_PATH}/${CONFIG_PRODUCT_NAME}
opt_outdir_intermediate=${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/obj/PACKAGING/subimg_intermediate
mkdir -p ${opt_outdir_intermediate}

if [ "is${CONFIG_BL_FASTLOGO}" != "isy" ]; then
  echo "No FASTLOGO configed!!!"
  exit 0
fi

if [ "is${CONFIG_GENX_ENABLE}" = "isy" ]; then
  if [ -f ${product_dir}/fastlogo.subimg.gz ]; then
    cp ${product_dir}/fastlogo.subimg.gz ${opt_outdir_intermediate}
    gunzip -f ${opt_outdir_intermediate}/fastlogo.subimg.gz
    mv ${opt_outdir_intermediate}/fastlogo.subimg ${opt_outdir_intermediate}/fastlogo_payload.subimg
  fi

  if [ -f ${opt_outdir_intermediate}/fastlogo_payload.subimg ]; then
    ${security_tools_path}in_extras.py "FASTLOGO" ${opt_outdir_intermediate}/in_fastlogo_extras.bin 0x00000001
    genx_secure_image "FASTLOGO" "ree" ${opt_outdir_intermediate}/in_fastlogo_extras.bin 0x0 ${opt_outdir_intermediate}/fastlogo_payload.subimg ${opt_outdir_intermediate}/fastlogo_en.subimg
  fi

  # Generate subimg
  ${basedir_tools}/prepend_image_info.sh ${opt_outdir_intermediate}/fastlogo_en.subimg ${outfile_fastlogo_subimg}
else
  if [ -f ${product_dir}/fastlogo.subimg.gz ]; then
    cp ${product_dir}/fastlogo.subimg.gz ${opt_outdir_intermediate}
    gunzip -f ${opt_outdir_intermediate}/fastlogo.subimg.gz
  fi
fi
