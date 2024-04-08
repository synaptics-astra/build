# Bash script: subimage: tee: default

### TODO(Song) should not use flash type to decide prepending or not ###
if [ "is${CONFIG_IMAGE_EMMC}" = "isy" ]; then
  ### Copy pre-built binary of tee with prepending image info ###
  ${basedir_tools}/prepend_image_info.sh ${outdir_tee_release}/tee_en.bin ${outfile_tee_subimg}
  if [ -f ${outdir_tee_release}/tee_recovery_en.bin ]; then
    ${basedir_tools}/prepend_image_info.sh ${outdir_tee_release}/tee_recovery_en.bin ${outfile_tee_recovery_subimg}
  fi
else
  ### Copy pre-built binary of tee ###
  #cp -ad ${outdir_tee_release}/tee_en.bin ${outfile_tee_subimg}
  ${basedir_tools}/prepend_image_info.sh ${outdir_tee_release}/tee_en.bin ${outfile_tee_subimg}
  if [ -f ${outdir_tee_release}/tee_recovery_en.bin ]; then
    ${basedir_tools}/prepend_image_info.sh ${outdir_tee_release}/tee_recovery_en.bin ${outfile_tee_recovery_subimg}
  fi
fi
