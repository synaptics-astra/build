# Bash script: subimage: tee: usb

if [ "is${CONFIG_GENX_MCU}" = "isy" ]; then
  process_cmd="cp"
else
  process_cmd="${basedir_tools}/prepend_image_info.sh"
fi

### Generate subimg ###
eval "${process_cmd} ${outdir_tee_release}/tee_en.bin ${outfile_tee_subimg}"
